use t::test_base;
use Data::Dumper;

BEGIN{
    use_ok("Eixo::Rest::ApiFakeServer");
    use_ok("Eixo::Rest::Client");
}

SKIP: {

    eval{ require "HTTP/Server/Simple/CGI.pm"};

    skip "HTTP::Server::Simple::CGI not installed", 2 if($@);

    my $pid;

    eval{
        $pid = Eixo::Rest::ApiFakeServer->new(

            listeners => {
                '/containers/json' => {
                    #header => sub {
                    #    print "HTTP/1.0 200 OK\r\n";
                    #    print $_[0]->cgi->header(-type  =>  'text/json');
                    #},
                    body => sub {
                    
                        print '[{"a":"TEST1"},{"b":"TEST2"}]';
                    }
                },
            }
        )->start(67891);


        my @calls;
        
        my $c = Eixo::Rest::Client->new('http://localhost:67891');
        
        $@ = undef;
        eval{
        	$c->noExiste;
        };
        ok($@ =~ /UNKNOW METHOD/, 'Non-existent Client methods launch exception');
        
        my $process_data = {
            onSuccess => sub {
                ok(
                    ref($_[0]) eq 'ARRAY' && $_[0]->[0]->{a} eq "TEST1", 
                    "onSuccess callback launched correctly",
                );

                # pass response
                return $_[0];
                
            },
        };

        my $callback = sub {

            ok(
                ref($_[0]) eq 'ARRAY' && $_[0]->[1]->{b} eq "TEST2", 
                'callback launched correctly'
            );

            ## pass response
            return $_[0];
        };
        
        # sync request
        my $h = $c->getContainers(
            GET_DATA => {all => 1},
            PROCESS_DATA => $process_data,
            __callback => $callback
        );

        ok(
            ref($h) eq 'ARRAY' && $h->[1]->{b} eq "TEST2", 
        	"Testing json response"
        );


    };
    if($@){
        print Dumper($@);
    }

    kill(9, $pid) if($pid);
    
}

done_testing();
