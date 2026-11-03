#add nicer summary pages for practice research outputs
#calling this dk - it's a little like dk, a little like kultur, not much like donkey kong

push @{ $c->{fields}->{eprint} },
{
    name => 'record_display',
    type => 'set',
    options => [qw(
        metadata
        media
    )],
    input_style => 'medium',
    sql_index => 0,
};

$c->{dk}->{vimeo_options} = "?loop=false&amp;byline=false&amp;portrait=false&amp;title=false&amp;speed=true&amp;transparent=0&amp;gesture=media";
$c->{dk}->{youtube_options} = "?origin=https://plyr.io&amp;iv_load_policy=3&amp;modestbranding=1&amp;playsinline=1&amp;showinfo=0&amp;rel=0&amp;enablejsapi=1";
$c->{dk}->{mime_exceptions} = [ qw# video/quicktime # ];

package EPrints::Plugin::ScriptPlugin;

use strict;

our @ISA = qw/EPrints::Plugin/;

package EPrints::Script::Compiled;

no warnings 'redefine';

sub run_has_type
{
    my( $self, $state, $eprint, $arg ) = @_;

    if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
    {
        $self->runtime_error( "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }
    my $repo = $state->{session}->get_repository;
    my $has = 0;
    my $type = $arg->[0];
    for my $doc ($eprint->[0]->get_all_documents){
      if($doc->value("mime_type") =~ m#^$type/# &&
          !grep $_ eq $doc->value("mime_type"), @{$repo->get_conf("dk","mime_exceptions")}){
        $has = 1;
        last;
      }
    }
    return [$has, "BOOLEAN"];
}

sub run_has_docs
{
    my( $self, $state, $eprint, $arg ) = @_;

    if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
    {
        $self->runtime_error( "has_docs) must be called on an eprint object. not : ".$eprint->[0] );
    }
    my $docs = $eprint->[0]->get_all_documents;
    my $has = $docs > 0  ? 1 : 0;
    return [$docs, "BOOLEAN"];
}


sub run_get_type
{
    my( $self, $state, $eprint, $arg ) = @_;

    if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
    {
        $self->runtime_error( "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }
    my $repo = $state->{session}->get_repository;
    my $type = $arg->[0];
    my $docs = [];
    if( $repo->can_call( "dk", "get_docs_by_type" ) )
    {
   $docs = $repo->call( [ "dk", "get_docs_by_type" ], $repo, $eprint->[0], $type );
    }

    return [$docs, "ARRAY"];
}

# does a field contain a url we want to display
sub run_url_is_video
{
    my( $self, $state, $eprint, $value ) = @_;

    if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
    {
        $self->runtime_error( "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }

    my $field_name = $value->[0];

    # get the url
    my $url = $eprint->[0]->get_value( $value->[0] );

    # if this url is represented by a document (i.e. it's a downloaded youtube video) don't show it again
    foreach my $doc ($eprint->[0]->get_all_documents)
    {
        foreach my $rel (@{$doc->value( "relation" )})
        {
            if( $rel->{type} eq EPrints::Utils::make_relation( "isYoutubeVideo" ) &&
                ( $url eq $rel->{uri} ) )
            {
                # we already have this url as an upload, so we don't need to display it again
                return [0, "BOOLEAN"];
            }
        }
    }

    return [1, "BOOLEAN"] if defined $url && $url =~ m#http(s)?://(www\.)?youtube#;
    return [1, "BOOLEAN"] if defined $url && $url =~ m#http(s)?://(www\.)?vimeo#;
    return [0, "BOOLEAN"];
}

# is a url a video we want to display
sub run_url_value_is_video
{
    my( $self, $state, $eprint, $value ) = @_;

    if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
    {
        $self->runtime_error( "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }

    # get the url
    my $url = $value->[0];

    # don't display if we have this elsewhere - i.e. if we have it in official url
    if( defined $url && $eprint->[0]->is_set( "official_url" ) && $eprint->[0]->get_value( "official_url" ) eq $url )
    {
        return [0, "BOOLEAN"];
    }

    # if this url is represented by a document (i.e. it's a downloaded youtube video) don't show it again
    foreach my $doc ($eprint->[0]->get_all_documents)
    {
        foreach my $rel (@{$doc->value( "relation" )})
        {
            if( $rel->{type} eq EPrints::Utils::make_relation( "isYoutubeVideo" ) &&
                ( $url eq $rel->{uri} ) )
            {
                # we already have this url as an upload, so we don't need to display it again
                return [0, "BOOLEAN"];
            }
        }
    }

    return [1, "BOOLEAN"] if defined $url && $url =~ m#http(s)?://(www\.)?youtube#;
    return [1, "BOOLEAN"] if defined $url && $url =~ m#http(s)?://(www\.)?vimeo#;
    return [0, "BOOLEAN"];
}


# checks if given field (e.g. related_url_url) contains a video URL - used to know if we need to display the video section
sub run_field_has_video {
    my($self, $state, $eprint, $value) = @_;
    if(!$eprint->[0]->isa("EPrints::DataObj::EPrint")) {
        $self->runtime_error(
            "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }
    my @urls = @{$eprint->[0]->get_value($value->[0])};
    foreach my $url ( @urls )
    {
        return [1, "BOOLEAN"] if $url =~ m#http(s)?://(www\.)?youtube#;
        return [1, "BOOLEAN"] if $url =~ m#http(s)?://(www\.)?vimeo#;
    }
    return [0, "BOOLEAN"];
}

sub run_url_to_embed
{
    my( $self, $state, $eprint, $value ) = @_;

    if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
    {
        $self->runtime_error( "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }
    my $repo = $state->{session}->get_repository;

    my $url = $eprint->[0]->get_value($value->[0]);

    $url =~ s#http(s)?://(www\.)?youtube.com/watch\?v=(.+)#https://www.youtube.com/embed/$3#;
    $url =~ s#http(s)?://(www\.)?youtu.be/(.+)#https://www.youtube.com/embed/$3#;

    $url =~ s#http(s)?://(www\.)?vimeo.com/(.+)#https://player.vimeo.com/video/$3#;
    if($url=~/vimeo/){
      $url.=$repo->get_conf("dk", "vimeo_options");
    }
    if($url=~/youtube/){
      $url.=$repo->get_conf("dk", "youtube_options");
    }
    return [$url, "STRING"];
}

sub run_url_value_to_embed
{
    my( $self, $state, $eprint, $value ) = @_;

    if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
    {
        $self->runtime_error( "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }
    my $repo = $state->{session}->get_repository;

    my $url = $value->[0];

    $url =~ s#http(s)?://(www\.)?youtube.com/watch\?v=(.+)#https://www.youtube.com/embed/$3#;
    $url =~ s#http(s)?://(www\.)?youtu.be/(.+)#https://www.youtube.com/embed/$3#;

    $url =~ s#http(s)?://(www\.)?vimeo.com/(.+)#https://player.vimeo.com/video/$3#;
    if($url=~/vimeo/){
      $url.=$repo->get_conf("dk", "vimeo_options");
    }
    if($url=~/youtube/){
      $url.=$repo->get_conf("dk", "youtube_options");
    }
    return [$url, "STRING"];
}


sub run_is_image
{
    my( $self, $state, $doc ) = @_;

    if( ! $doc->[0]->isa( "EPrints::DataObj::Document") )
    {
        $self->runtime_error( "is_image() must be called on a document object." );
    }
    $doc = $doc->[0];
    return [1, "BOOLEAN"] if $doc->value("mime_type") =~ m#^image/#;
    return [0, "BOOLEAN"];

}

sub run_iiif_manifest_enabled {

  my( $self, $state, $eprint, $arg ) = @_;

  my $repo = $state->{session}->get_repository;
  my $iiif_disable = $repo->get_conf('plugins','Export::IIIFManifest','params','disable');
  print STDERR "iiif diable value: $iiif_disable\n";
  return [1, "BOOLEAN"] if(defined $iiif_disable && $iiif_disable == 0) ;

  return [0, "BOOLEAN"]
}

# checks if given field (e.g. official_url) contains an audio URL - used to know if we need to display the audio section and when rendering an individual value
sub run_url_is_audio {
    my($self, $state, $eprint, $value) = @_;

    if(!$eprint->[0]->isa("EPrints::DataObj::EPrint")) {
        $self->runtime_error(
            "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }
    my $url = $eprint->[0]->get_value($value->[0]);
    return [1, "BOOLEAN"] if $url =~ m#(http(s)?://(www\.)?)?soundcloud#;
    return [0, "BOOLEAN"];
}

# checks if given field (e.g. related_url_url) contains an audio URL - used to knwo if we need to display the audio section
# checks all values in a field rather than an individual value, distinguishing it from run_url_value_is_audio
sub run_field_has_audio {
    my($self, $state, $eprint, $value) = @_;
    if(!$eprint->[0]->isa("EPrints::DataObj::EPrint")) {
        $self->runtime_error(
            "has_type() must be called on an eprint object. not : ".$eprint->[0] );
    }
    my @urls = @{$eprint->[0]->get_value($value->[0])};
    foreach my $url ( @urls )
    {
        return [1, "BOOLEAN"] if $url =~ m#(http(s)?://(www\.)?)?soundcloud#;
    }
    return [0, "BOOLEAN"];
}

# pass a URL value from a field (e.g. related_url field) - used when emedding audio urls
sub run_url_value_is_audio {
  my( $self, $state, $eprint, $value ) = @_;
  if( !$eprint->[0]->isa( "EPrints::DataObj::EPrint" ) )
  {
    $self->runtime_error( "has_type() must be called on an eprint object. not : ".$eprint->[0] );
  }

  my $url = $value->[0];
    # if this url is already an official url, don't embed the audio again
    if( defined $url && $eprint->[0]->is_set( "official_url" ) && $eprint->[0]->get_value( "official_url" ) eq $url )
    {
    return [0, "BOOLEAN"];
    }

  return [1, "BOOLEAN"] if $url =~ m#(http(s)?://(www\.)?)?soundcloud#;
  return [0, "BOOLEAN"];
}

