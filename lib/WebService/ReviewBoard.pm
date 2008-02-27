package WebService::ReviewBoard;

use strict;
use warnings;

use JSON::Syck;
use Data::Dumper;
use Log::Log4perl qw(:easy);
use HTTP::Request::Common;
use LWP::UserAgent;
use version; our $VERSION = qv('0.0.1');

use WebService::ReviewBoard::Review;
use vars qw($REVIEW_BOARD_URL);

sub new {
	my $proto = shift;
	$REVIEW_BOARD_URL = shift or LOGDIE "usage: " .  __PACKAGE__ . "->new( 'http://demo.review-board.org' );";

	my $class = ref $proto || $proto;
	my $self = {};

	return bless $self, $class;
}

# this is a class method
sub get_review_board_url {
    # blech, globals.  lame.
	if ( !$REVIEW_BOARD_URL ) {
		LOGDIE "get_review_board_url(): please first construct a WebService::ReviewBoard object";
	}

	return $REVIEW_BOARD_URL;
}

sub login {
	my $self     = shift;
	my $username = shift or LOGCROAK "you must pass WebService::ReviewBoard->login a username";
	my $password = shift or LOGCROAK "you must pass WebService::ReviewBoard->login a password";

	my $json = _api_post(
		$self->_get_ua(),
		'/api/json/accounts/login/',
		[
			username => $username,
			password => $password
		]
	);

	return 1;
}

sub create_review {
	my $self = shift;
	my $args = shift;

	my $ua = $self->_get_ua();
	my $json = _api_post( $ua, '/api/json/reviewrequests/new/', $args );

	if ( !$json->{review_request} ) {
		LOGDIE "create_review couldn't determine ID from this JSON that it got back from the server: " . Dumper $json;
	}

	return bless { ua => $ua, id => $json->{review_request}->{id} }, 'WebService::ReviewBoard::Review';

}

# this is a class method
sub _api_post {
	my $ua   = shift or LOGCONFESS "_api_post needs an LWP::UserAgent as first arg";
	my $path = shift or LOGDIE "No path to _api_post";
	my @post_options = @_;

    
	my $url = get_review_board_url() . $path;
	my $request = POST( $url, @post_options );
	DEBUG "Doing request:\n" . $request->as_string();
	my $response = $ua->request($request);
	DEBUG "Got response:\n" . $response->as_string();

	my $json;
	if ( $response->is_success ) {
		$json = JSON::Syck::Load( $response->content() );
	}
	else {
		LOGDIE "Error fetching $path: " . $response->status_line . "\n";
	}

	# check if there was an error
	if ( $json->{err} && $json->{err}->{msg} ) {
		LOGDIE "Error from $url: " . $json->{err}->{msg};
	}

	return $json;
}

sub _get_ua {
	my $self = shift or LOGCROAK "you must call _get_ua as a method";

	if ( !$self->{ua} ) {
		$self->{ua} = LWP::UserAgent->new( cookie_jar => {}, );
	}

	return $self->{ua};

}

1;

__END__

=head1 NAME

WebService::ReviewBoard - Perl library to talk to a review board installation thru web services.

=head1 VERSION

This document describes WebService::ReviewBoard version 0.0.1

=head1 SYNOPSIS

    use WebService::ReviewBoard;

    # pass in the name of the reviewboard url to the constructor
    my $rb = WebService::ReviewBoard->new( 'http://demo.review-board.org/' );
    $rb->login( 'username', 'password' );

    # create_review returns a WebService::ReviewBoard::Review object 
    my $review = $rb->create_review();
  
=head1 DESCRIPTION

This is an alpha release of C<< WebService::ReviewBoard >>.  The interface may change at any time and there
are many parts of the API that are not implemented.  You've been warned!

Patches welcome!

=head1 INTERFACE 

=over 

=item C<< create_review( $args ) >>

Must pass in which repository to use.  Using one of these (from the API documentation):

    * repository_path: The repository to create the review request against. If not specified, the DEFAULT_REPOSITORY_PATH setting will be used. If both this and repository_id are set, repository_path's value takes precedence.
    * repository_id: The ID of the repository to create the review request against. 

Example:

    my $review = $rb->create_review( [ respository_id => 1 ] );

=item C<< get_review_board_url >>

=item C<< login >>

=back

=head1 DIAGNOSTICS

=over

=item C<< "you must pass WebService::ReviewBoard->new a username" >>

=item C<< "you must pass WebService::ReviewBoard->new a password" >>

=item C<< "create_review couldn't determine ID from this JSON that it got back from the server: %s" >>

=item C<< "_api_post needs an LWP::UserAgent as first arg" >>

=item C<< "No path to _api_post" >>

=item C<< "Error fetching %s: %s" >>

=item C<< "you must call %s as a method" >>

=item C<< "get_review_board_url(): please first construct a WebService::ReviewBoard object" >>

=item C<< "Need a field name at (eval 38) line 1" >>

I'm not sure where this error is coming from, but it seems to be when you fail to pass a repository
path or id to C<< create_review >> method.



=back

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

    version
    YAML::Syck
    Data::Dumper
    Bundle::LWP
    Log::Log4Perl

There are also a bunch of Test::* modules that you need if you want all the tests to pass:

    Test::More
    Test::Pod
    Test::Exception
    Test::Pod::Coverage
    Test::Perl::Critic

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-webservice-reviewboard@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Jay Buffington  C<< <jaybuffington@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Jay Buffington C<< <jaybuffington@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
