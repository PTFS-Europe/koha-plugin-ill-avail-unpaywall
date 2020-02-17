package Koha::Plugin::Com::PTFSEurope::AvailabilityUnpaywall;

use Modern::Perl;

use base qw( Koha::Plugins::Base );
use Koha::DateUtils qw( dt_from_string );
use Koha::Database;

use Cwd qw( abs_path );
use CGI;
use LWP::UserAgent;
use HTTP::Request;
use JSON qw( encode_json decode_json );
use Digest::MD5 qw( md5_hex );
use MIME::Base64 qw( decode_base64 );
use URI::Escape qw ( uri_unescape );

our $VERSION = "1.0.1";

our $metadata = {
    name            => 'ILL availability - Unpaywall',
    author          => 'Andrew Isherwood',
    date_authored   => '2019-07-09',
    date_updated    => "2019-07-09",
    minimum_version => '18.11.00.000',
    maximum_version => undef,
    version         => $VERSION,
    description     => 'This plugin provides ILL availability searching for the Unpaywall API'
};

sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    $self->{schema} = Koha::Database->new()->schema();
    $self->{config} = decode_json($self->retrieve_data('avail_config') || '{}');

    return $self;
}

# Recieve a hashref containing the submitted metadata
# and, if we can work with it, return a hashref of our service definition
sub ill_availability_services {
    my ($self, $params) = @_;

    # A list of metadata properties we're interested in
    my $properties = [ 'doi' ];

    # Establish if we can service this item
    my $can_service = 0;
    foreach my $property(@{$properties}) {
        if (
            $params->{metadata}->{$property} &&
            length $params->{metadata}->{$property} > 0
        ) {
            $can_service++;
        }
    }

    # Do we have a configured email address
    my $email = $self->{config}->{ill_avail_unpaywall_email};
    $email =~ s/^\s+|\s+$//g;
    if ($email || length $email > 0) {
        $can_service++;
    }

    # Can we display our results in this UI context
    my $ui_context = $params->{ui_context};
    if ($self->{config}->{"ill_avail_unpaywall_display_${ui_context}"}) {
        $can_service++;
    }


    # Bail out if we can't do anything with this request
    return 0 if $can_service < 3;

    my $endpoint = '/api/v1/contrib/' . $self->api_namespace .
        '/ill_availability_search_unpaywall?metadata=';

    return {
        # Our service should have a reasonably unique ID
        # to differentiate it from other service that might be in use
        id => md5_hex(
            $self->{metadata}->{name}.$self->{metadata}->{version}
        ),
        plugin     => $self->{metadata}->{name},
        endpoint   => $endpoint,
        datatablesConfig => {
            processing => 'true',
            colvis     => 'false'
        }
    };
}

sub api_routes {
    my ($self, $args) = @_;

    my $spec_str = $self->mbf_read('openapi.json');
    my $spec = decode_json($spec_str);

    return $spec;
}

sub api_namespace {
    my ($self) = @_;

    return 'ill_availability_unpaywall';
}

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('save') ) {

        my $template = $self->get_template({ file => 'configure.tt' });
        $template->param(
            config => $self->{config}
        );

        $self->output_html( $template->output() );
    }
    else {
        my %blacklist = ('save' => 1, 'class' => 1, 'method' => 1);
        my $hashed = { map { $_ => (scalar $cgi->param($_))[0] } $cgi->param };
        my $p = {};
        foreach my $key (keys %{$hashed}) {
           if (!exists $blacklist{$key}) {
               $p->{$key} = $hashed->{$key};
           }
        }
        $self->store_data({ avail_config => scalar encode_json($p) });
        print $cgi->redirect(-url => '/cgi-bin/koha/plugins/run.pl?class=Koha::Plugin::Com::PTFSEurope::AvailabilityUnpaywall&method=configure');
        exit;
    }
}

sub install() {
    return 1;
}

sub upgrade {
    my ( $self, $args ) = @_;

    my $dt = dt_from_string();
    $self->store_data(
        { last_upgraded => $dt->ymd('-') . ' ' . $dt->hms(':') }
    );

    return 1;
}

sub uninstall() {
    return 1;
}

1;
