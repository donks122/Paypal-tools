package Masspay;
use warnings;
use Business::PayPal::API;
use Business::PayPal::API::MassPay;
eval {require './paypal.conf';};


sub transfertopaypal  {

    my $open_list ={};# get the list of payments to be done from flat file or DB
    my $hash = {};
    while (my $tr = $open_list->get_next){
        #Sort them wrt currency
        $hash->{$tr->currency}->{$tr->id} = { ReceiverEmail => $tr->paypal_email, 
                                              Amount => $tr->amount, 
                                              currencyID => $tr->currency, 
                                              Note => $tr->transfer_note, 
                                              Fee => $tr->transfer_fee, 
                                              Status => $tr->status,
                                              userid => $tr->userid,
                                              date => $tr->date->ymd
                                            };

    }
      my $pp = new Business::PayPal::API::MassPay
          ( Username       => 'paypal_API_username',
            Password       => 'password',
            Signature      => 'signature text',
            sandbox        => 0,
          );

        foreach my $keys (keys %$hash){
            my @receiverlist;
            my @success_ids;
            foreach my $id ( keys %{$hash->{$keys}}){
                my $amount = $hash->{$keys}->{$id}->{Amount} - $hash->{$keys}->{$id}->{Fee};
                $amount = sprintf("%.2f",$amount); 
                my $row = {
                    ReceiverEmail => $hash->{$keys}->{$id}->{ReceiverEmail},
                    Amount => $amount,
                    currencyID => $hash->{$keys}->{$id}->{currencyID},
                    Note => $hash->{$keys}->{$id}->{Note}
                    };
                push (@receiverlist , $row);
                push (@success_ids , $id);
            }
            while ( scalar(@receiverlist) > 0 ) {
                my @tmp = splice(@receiverlist,0,249);
                my @update_ids = splice(@success_ids,0,249);
                $c->log->info( Dumper @tmp);
                my %resp = $pp->MassPay( EmailSubject => "Your Payment From Company",
                               currencyID => $tmp[0]->{currencyID},
                               MassPayItems => \@tmp );
                if ( $resp{Ack} eq 'Success' ){
                    print Dumper %resp ;
                   # my $update_ids = join(",",@update_ids);
                    $update_list->update({status  => 'closed'});
                } else {
                    print ( Dumper %resp ); #$resp{Errors}[0]{LongMessage}
                }
            }
        }
}

=head1 AUTHOR

Sandeep Nyamati (sandeep.nyamati@gmail.com)

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
1;
