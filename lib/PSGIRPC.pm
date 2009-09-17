package PSGIRPC;
use strict;
use warnings;
our $VERSION = '0.01';

use Data::Dumper;

sub _pack {
    my($serializer, $data) = @_;
    if ($serializer == 3) {
        return Dumper($data);
    } else {
        die "cant detect serializer type: $serializer";
    }
}

sub _unpack {
    my($serializer, $data) = @_;
    if ($serializer == 3){
        my $VAR1;
        eval $data; ## no critic
        die "desirialize error: $@" if $@;
        return $VAR1;
    } else {
        die "cant detect serializer type: $serializer";
    }
}

sub _unpack_prepare {
    my($packed, $header) = @_;
    my $ua;
    unless ($header) {
        ($packed, $ua, $header) = $packed =~ /^(.+?\015\012)(.+?)\015\012(.+)/s;
    }
    $packed =~ s/\015\012$//;
    my(@ret) = split ' ', $packed;

    my $rpc_header = +{
        version     => $ret[0],
        request_id  => $ret[1],
        serializer  => $ret[2],
        header_size => $ret[3],
        ua          => $ua,
    };
    ($rpc_header, $header, \@ret);
}

sub from_psgi_request {
    my($req_id, $serializer, $ua, $psgi) = @_;
    my $strip_env = +{ %{ $psgi } };
    delete $strip_env->{'psgi.input'};
    delete $strip_env->{'psgi.errors'};
    my $dump = _pack($serializer, $strip_env);
    sprintf "0.9 %s %s %d\015\012$ua\015\012%s\015\012", $req_id, $serializer, length($dump), $dump;
}

sub to_psgi_request {
    my($rpc_header, $header) = _unpack_prepare(@_);
    my $unpacked = _unpack($rpc_header->{serializer}, $header);
    ($rpc_header, $unpacked);
}

sub from_psgi_response {
    my($req_id, $serializer, $ua, $psgi) = @_;
    my $dump = _pack($serializer, $psgi->[1]);
    sprintf "0.9 %s %s %d %s\015\012$ua\015\012%s\015\012", $req_id, $serializer, length($dump), $psgi->[0], $dump;
}

sub to_psgi_response {
    my($rpc_header, $header, $ret) = _unpack_prepare(@_);
    $rpc_header->{status} = $ret->[4];
    my $unpacked = _unpack($rpc_header->{serializer}, $header);
    ($rpc_header, [ $ret->[4], $unpacked, [] ]);
}

1;
__END__

=encoding utf8

=head1 NAME

PSGIRPC -

=head1 SYNOPSIS

  use PSGIRPC;

=head1 DESCRIPTION

PSGIRPC is

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 SEE ALSO

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/PSGIRPC/trunk PSGIRPC

PSGIRPC is Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
