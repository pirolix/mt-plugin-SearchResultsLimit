package MT::Plugin::OMV::SearchResultsLimit;
use strict;
#  SearchResultsLimit - 
#           Original Copyright (c) 2007 Piroli YUKARINOMIYA (MagicVox)
#           Open MagicVox.net - http://www.magicvox.net/
#           @see http://www.magicvox.net/

use MT;
use MT::Template::Context;
use MT::App::Search;
#use MT::App::Search::Context;# not need ?
eval {
    # Enable the high-resolution time function, if you can.
    use Time::HiRes qw( time );
};

use vars qw( $MYNAME $VERSION $VERBOSE );
$MYNAME = 'SearchResultsLimit';
$VERSION = '1.00 DEVEL';
$VERBOSE = 0;

use base qw( MT::Plugin );
my $plugin = new MT::Plugin ({
        name => $MYNAME,
        version => $VERSION,
        author_name => '<MT_TRANS phrase="Piroli YUKARINOMIYA">',
        author_link => "http://www.magicvox.net/?$MYNAME",
        doc_link => "http://www.magicvox.net/archive/2007/09292314/?$MYNAME",
        description => '<MT_TRANS phrase="Expand some tags for the limitations by the count and processing time in search results template.">',
});
MT->add_plugin ($plugin);

sub instance { $plugin; }



### Container - MTSearchResultsLimit
MT::Template::Context->add_container_tag (SearchResultsLimit => \&search_results_limit);
sub search_results_limit {
    my ($ctx, $args, $cond) = @_;

    $ctx->{__stash}{__PACKAGE__}{body_count} = 0;
    $ctx->{__stash}{__PACKAGE__}{limitup_count_flag} = undef;
    $ctx->{__stash}{__PACKAGE__}{limitup_time_flag} = undef;
    $ctx->{__stash}{__PACKAGE__}{start_time} = time;

    $ctx->{__stash}{__PACKAGE__}{min_n} = $args->{'min_n'} || undef;
    $ctx->{__stash}{__PACKAGE__}{max_n} = $args->{'max_n'} || undef;
    $ctx->{__stash}{__PACKAGE__}{'time'} = $args->{'time'} || undef;

    # Original searching
    MT::App::Search::Context::_hdlr_results ($ctx, $args, $cond);
}



### Conditional - MTSearchResultsLimitBody
MT::Template::Context->add_conditional_tag (SearchResultsLimitBody => \&search_results_limit_body);
sub search_results_limit_body {
    my ($ctx, $args, $cond) = @_;

    # already limited up
    return 0
        if defined $ctx->{__stash}{__PACKAGE__}{limitup_count_flag}
            || defined $ctx->{__stash}{__PACKAGE__}{limitup_time_flag};

    # count up
    my $body_count = ++$ctx->{__stash}{__PACKAGE__}{body_count};

    # Guarantee of minimum results to show
    my $min_nl = $ctx->{__stash}{__PACKAGE__}{min_n};
    if (defined $min_nl && $body_count <= $min_nl) {
        return 1;
    }

    # Limitation of maximum results to show
    my $max_nl = $ctx->{__stash}{__PACKAGE__}{max_n};
    if (defined $max_nl && $max_nl < $body_count) {
        $ctx->{__stash}{__PACKAGE__}{limitup_count_flag} = 0;
        return 0;
    }

    # Limitation of templates processing time
    my $time_l = $ctx->{__stash}{__PACKAGE__}{'time'};
    if (defined $time_l && $time_l <= time - $ctx->{__stash}{__PACKAGE__}{start_time}) {
        $ctx->{__stash}{__PACKAGE__}{limitup_time_flag} = 0;
        return 0;
    }
    1;
}

### Conditional - MTSearchResultsLimitCountUp
MT::Template::Context->add_conditional_tag (SearchResultsLimitCountUp => \&search_results_limit_count_up);
sub search_results_limit_count_up {
    my $limitup_count_flag = $_[0]->{__stash}{__PACKAGE__}{limitup_count_flag};

    defined $limitup_count_flag && !$limitup_count_flag;
}

### Conditional - MTSearchResultsLimitTimeUp
MT::Template::Context->add_conditional_tag (SearchResultsLimitTimeUp => \&search_results_limit_time_up);
sub search_results_limit_time_up {
    my $limitup_time_flag = $_[0]->{__stash}{__PACKAGE__}{limitup_time_flag};

    defined $limitup_time_flag && !$limitup_time_flag;
}

### Conditional - MTSearchResultsLimitUp
MT::Template::Context->add_conditional_tag (SearchResultsLimitUp => \&search_results_limit_up);
sub search_results_limit_up {
    search_results_limit_count_up (@_) || search_results_limit_time_up (@_);
}



### Tag - MTSearchResultsTime
MT::Template::Context->add_tag (SearchResultsTime => \&search_results_time);
sub search_results_time {
    (time - $_[0]->{__stash}{__PACKAGE__}{start_time}) * 1000;
}

### Tag - MTSearchResultsTime
MT::Template::Context->add_tag (SearchResultsMaxCount => \&search_results_max_count);
sub search_results_max_count {
    $_[0]->{__stash}{__PACKAGE__}{max_n};
}

1;
