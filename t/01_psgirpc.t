use strict;
use warnings;
use Test::More;
use Test::Requires qw(Data::Dumper;);

use PSGIRPC;

my $req_id = time;
do {
    my $psgi_req = {
        SERVER_PORT         => 80,
        SERVER_NAME         => 'example.com',
        SCRIPT_NAME         => '',
        REMOTE_ADDR         => '127.0.0.1',
        'psgi.version'      => [ 1, 0 ],
        'psgi.input'        => 'foo input',
        'psgi.errors'       => 'bar error',
        'psgi.url_scheme'   => 'http',
        'psgi.run_once'     => 0,
        'psgi.multithread'  => 0,
        'psgi.multiprocess' => 0,
        HTTP_USER_AGENT     => 'Test/0.1',
        HTTP_ACCEPT         => '*/*'
    };
    my $packed_header = sprintf "0.9 %s 3 509\015\012", $req_id;

    my $packed = PSGIRPC::from_psgi_request($req_id, 3, $psgi_req);
    my $got_packed_header = $packed;
    $got_packed_header =~ s/^([^\015]+\015\012).+$/$1/s;
    is($got_packed_header, $packed_header, 'request packed');


    my($got_headers, $unpacked) = PSGIRPC::to_psgi_request($packed);
    is_deeply($got_headers, +{
        version     => '0.9',
        request_id  => $req_id,
        serializer  => 3,
        header_size => 509,
    }, 'request headers');

    $unpacked->{'psgi.input'}  = $psgi_req->{'psgi.input'};
    $unpacked->{'psgi.errors'} = $psgi_req->{'psgi.errors'};
    is_deeply($unpacked, $psgi_req, 'request unpacked');
};

do {
    my $psgi_res = [
        200,
        [
            'Content-Type'   => 'text/html',
            'Content-Length' => '5',
        ],
        [ 'hokke' ]
    ];
    my $packed_header = sprintf "0.9 %s 3 112 200\015\012", $req_id;
    my $packed = PSGIRPC::from_psgi_response($req_id, 3, $psgi_res);
    my $got_packed_header = $packed;
    $got_packed_header =~ s/^([^\015]+\015\012).+$/$1/s;
    is($got_packed_header, $packed_header, 'response packed');


    my($got_headers, $unpacked) = PSGIRPC::to_psgi_response($packed);
    is_deeply($got_headers, +{
        version     => '0.9',
        request_id  => $req_id,
        serializer  => 3,
        header_size => 112,
        status      => 200,
    }, 'request headers');

    $unpacked->[2] = ['hokke'];
    is_deeply($unpacked, $psgi_res, 'response unpacked');
};



done_testing();

