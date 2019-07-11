package Koha::Plugin::Com::PTFSEurope::AvailabilityUnpaywall::Api;

 # This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;

use JSON qw( decode_json );
use MIME::Base64 qw( decode_base64 );
use URI::Escape qw ( uri_unescape );
use LWP::UserAgent;
use HTTP::Request::Common;

use Mojo::Base 'Mojolicious::Controller';
use Koha::Database;
use Koha::Plugin::Com::PTFSEurope::AvailabilityUnpaywall;

sub search {

    # Validate what we've received
    my $c = shift->openapi->valid_input or return;

    my $base_url = "https://api.unpaywall.org/v2/";

    # Check we've got an email address to append to the API call
    # Error if not
    my $plugin = Koha::Plugin::Com::PTFSEurope::AvailabilityUnpaywall->new();
    my $config = decode_json($plugin->retrieve_data('avail_config') || '{}');
    my $email = $config->{ill_avail_unpaywall_email};
    $email =~ s/^\s+|\s+$//g;
    if (!$email || length $email == 0) {
        return $c->render(
            status => 200,
            openapi => {
                results => {
                    search_results => [],
                    errors => [ { message => 'No email address configured' } ]
                }
            }
        );
    }

    # Gather together what we've been passed
    my $metadata = $c->validation->param('metadata') || '';
    $metadata = decode_json(decode_base64(uri_unescape($metadata)));
    # Get the DOI
    my $doi = $metadata->{doi};

    my $ua = LWP::UserAgent->new;
    my $response = $ua->request(GET "${base_url}${doi}?email=$email");

    if ( $response->is_success ) {
        my $to_send = [];
        # Parse the Unpaywall response and prepare our response
        my $data = decode_json($response->decoded_content);
        if ($data->{is_oa}) {
            my @authors = map {
                $_->{given} . ' ' . $_->{family}
            } @{$data->{z_authors}};
            push @{$to_send}, {
                title  => $data->{title},
                author => join(', ', @authors),
                url    => $data->{best_oa_location}->{url_for_landing_page},
                source => $data->{best_oa_location}->{repository_institution},
                date   => $data->{best_oa_location}->{published_date}
            };
        } else {
            $to_send = [];
        }

        return $c->render(
            status => 200,
            openapi => {
                results => {
                    search_results => $to_send,
                    errors => []
                }
            }
        );
    } else {
        return $c->render(
            status => 200,
            openapi => {
                results => {
                    search_results => [],
                    errors => [ { message => $response->status_line } ]
                }
            }
        );
    }

}

1;
