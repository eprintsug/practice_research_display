# practice_research_display
An ingredient that adds suite of display enhancements for EPrints to better present practice research outputs. Building on work from the previous Kultur and Dorian bazaar packages

This introduces two versions of summary pages:
- **Metadata** - a traditional summary page that foregrounds metadata. The main panel of the page is dedicated to metadata and files are displayed in a smaller panel
- **Media** - a gallery-esque display for records containing predominantly images and/or video files. The main panel is a tile-wall of images and/or a video player and metadata is displayed in a smaller panel

A new field is added to allow users to select which display they would like to use. This can also be set automatically based on various conditions such as file type and output type

## Installation Notes
This plugin uses Material features (most notably image\-lists) and is therefore dependent on the Material ingredient.
You will need to add the field for setting the display type to the workflow (and decide whether this will be available to all users or just staff). Alternatively you could choose to only ever use the automatically selected display and therefore keep it out of the workflow.

It's recommended to add the following to eprints\_fields\_automatic.pl (with the types amended to be all the types that you want to have this display by default):

```
    my $official_url = "";
    $official_url = $eprint->value( "official_url" ) if $eprint->is_set( "official_url" );
    my $related_url = $eprint->value( "related_url_url" );
    if( !$eprint->is_set("record_display") && defined $type && (
      $type eq 'video' ||
      $type eq 'image' ||
      $official_url =~ m#http(s)?://(www\.)?youtube# ||
      $official_url =~ m#http(s)?://(www\.)?vimeo# ||
      $related_url =~ m#http(s)?://(www\.)?youtube# ||
      $related_url =~ m#http(s)?://(www\.)?vimeo#
      )
    )
    {
      $eprint->set_value( "record_display", "media" )
    }
```
You'll also need to ensure all citations are in place at the local archive level. This may involve some amount of combining your existing summary_page citation with the one introduced here.

## Usage Notes
During development, this plugin was being called DK Display (based on its Dorian and Kultur ancestors) so many of the variables use the code 'dk'. This may be revisited in future depending on how annoying it is to remember that variables differ from the proper ingredient name.

## Future Enhancements
- The video display currently uses plyr (as did Dorian), which is deprecated and doesn't work nicely with all file types. In future updating to a supported media viewer that can display all (or at least more) file formats.
- Related to this, the version of jquery used is very much deprecated. Updating (or removing reliance on) this may be a happy side effect of updating the player but needs doing regardless.
