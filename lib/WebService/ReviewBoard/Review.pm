package WebService::ReviewBoard::Review;

use strict;
use warnings;

use Data::Dumper;
use Log::Log4perl qw(:easy);

sub _api_post {
	my $self   = shift;
	my $action = shift;

	return WebService::ReviewBoard::_api_post( $self->_get_ua(), "/api/json/reviewrequests/" . $self->get_id() . "/$action/",
		@_ );
}

sub _get_ua {
	my $self = shift;
	if ( !$self->{ua} ) {
		LOGDIE __PACKAGE__ . " wasn't initialized properly with a LWP::UserAgent object";
	}

	return $self->{ua};
}

sub get_id {
	my $self = shift;

	if ( !$self->{id} ) {
		LOGDIE "requested id, but id isn't set";
	}

	return $self->{id};
}

sub set_description { return shift->_set_field( 'description', @_ ); }
sub set_summary     { return shift->_set_field( 'summary',     @_ ); }
sub set_bugs        { return shift->_set_field( 'bugs_closed', join( ',', @_ ) ); }

sub _set_field {
	my $self  = shift;
	my $field = shift;
	my $value = shift;

	return $self->_api_post( "draft/set/$field", [ value => $value, ] );
}

sub set_reviewers {
	my $self      = shift;
	my @reviewers = @_;

	my $json = $self->_set_field( "target_people", join( ',', @reviewers ) );

#XXX parse json and return a list of reviewers actually added:
#{"stat": "ok",
#    "invalid_target_people": [],
#    "target_people": [{"username": "jaybuff", "url": "\/users \/jaybuff\/", "fullname": "Jay Buffington", "id": 1, "email": "jaybuff@yahoo-inc.com"}, {"username": "jdagnall", "url": "\/users\/jdagnall\/", "fullname": "Jud Dagnall", "id": 2, "email": "jdagnall@yahoo-inc .com"}]}

	return 1;
}

sub publish {
	my $self = shift;

	my $path = "/r/" . $self->get_id() . "/publish/";
	my $ua   = $self->_get_ua();

	#XXX I couldn't get reviews/draft/publish from the web api to work, so I did this hack for now:
	# I asked the review-board mailing list about this.  Waiting for a response...
	use HTTP::Request::Common;
	my $request = POST( WebService::ReviewBoard::get_review_board_url() . $path );
	DEBUG "Doing request:\n" . $request->as_string();
	my $response = $ua->request($request);
	DEBUG "Got response:\n" . $response->as_string();

	#   $self->_api_post(
	#		'reviews/draft/publish',
	#		[
	#			diff_revision => 1,
	#			shipit        => 0,
	#			body_top      => undef,
	#			body_bottom   => undef,
	#		]
	#	);

	return 1;
}

sub add_diff {
	my $self    = shift;
	my $file    = shift;
	my $basedir = shift;

	my $args = [ path => [$file] ];

	# base dir is used only for some SCMs (like SVN) (I think)
	if ($basedir) {
		push @{$args}, ( basedir => $basedir );
	}

	$self->_api_post( 'diff/new', Content_Type => 'form-data', Content => $args );

	return 1;
}

1;
__END__

WebService::ReviewBoard::Review - An object that represents a review on the review board system

=head1 SYNOPSIS

    # do not construct a WebService::ReviewBoard::Review object directly.  
    # use WebService::ReviewBoard::create_review() method instead
    use WebService::ReviewBoard;

    my $rb = WebService::ReviewBoard->new( 'http://demo.review-board.org' );
    $rb->login( 'username', 'password' );
    $review = $rb->create_review( ); # returns a WebService::ReviewBoard::Review object
    $review->set_bugs( 1728212, 1723823  );
    $review->set_reviewers( qw( jdagnall gno ) );
    $review->set_summary( "this is the summary" );
    $review->set_description( "this is the description" );
    $review->add_diff( '/tmp/patch' ); 
    $review->publish();

  
=head1 DESCRIPTION

=head1 INTERFACE 

=over

=item C<< new() >>

Do not use this constructor.  To construct a C<< WebService::ReviewBoard::Review >> object use the 
C<< create_review >> method in the C<< WebService::ReviewBoard >> class.

=item C<< get_id() >>

Returns the id of this review request

=item C<< set_bugs( @bug_ids ) >>

=item C<< set_reviewers( @review_board_users ) >>

=item C<< set_summary( $summary ) >>

=item C<< set_description( $description ) >>

=item C<< add_diff( $diff_file ) >>

C<< $diff_file >> should be a file on the disc that contains the diff that you want to be reviewed.

=item C<< publish( ) >>

Mark the review request as ready to be reviewed.  This will send out notification emails if review board 
is configured to do that. 

=back

=head1 DIAGNOSTICS

=over

=item C<< "requested id, but id isn't set" >>
=item C<< "WebService::ReviewBoard::Review wasn't initialized properly with a LWP::UserAgent object" >>

=back

=head1 CONFIGURATION AND ENVIRONMENT

C<< WebService::ReviewBoard::Review >> requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<< WebService::ReviewBoard >>

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
