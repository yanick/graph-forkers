#!/usr/bin/perl 

use 5.10.0;

use strict;
use warnings;

use Net::GitHub::V2::Repositories;
use Net::GitHub::V2::Users;
use List::MoreUtils qw/ part any uniq /;
use Data::Dumper;

my $repos = Net::GitHub::V2::Repositories->new(
    owner => 'yanick',
    repo => 'git-cpan-patch',
    login => 'yanick',
    token => $ENV{GITHUB_TOKEN},
);

my %project;
use DBM::Deep;

tie %project, 'DBM::Deep', 'projects';

my @seen_users;
my @todo_users;

tie @seen_users, 'DBM::Deep', 'seen_users';
tie @todo_users, 'DBM::Deep', 'todo_users';

harvest_user(shift @todo_users);

#print Dumper \%project;
#print Dumper \@seen_users;
print "todos remaining: ", 0+@todo_users, "\n";
print Dumper [ @todo_users[0..5] ];
exit;



sub harvest_project {
    my ( $user, $repo ) = @_;

    warn "harvesting $user/$repo\n";

    if ( my $r = $project{$repo} ) {
        if ( any { $_ eq $user }  keys( %$r ), map { @$_ } values ( %$r ) ) {
            warn "\t$user/$repo already harvested\n";
            return;
        }
    }

    my $repos = Net::GitHub::V2::Repositories->new(
        owner => $user,
        repo  => $repo,
        login => 'yanick',
        token => $ENV{GITHUB_TOKEN},
    );

    my $n = $repos->network;
    my @network = @{ $n || [] };

    # find the head vampire and minions
    my ( $owner, $forkers ) = part { $_->{fork} } @network;
    $owner = $owner->[0];

    $project{$owner->{name}}{$owner->{owner}} = [
        map { $_->{owner} } @$forkers
    ] if $forkers;

    for ( $owner->{owner}, map { $_->{owner} } @$forkers ) {
            next if $_ eq $user;
            next if $_ ~~ @seen_users;
            next if $_ ~~ @todo_users;
            push @todo_users, $_;
    }
}

sub harvest_user {
    my ( $user ) = @_;

    return if $user eq 'gitpan' or $user eq 'mirrors';

    my $u = Net::GitHub::V2::Users->new(
        owner => $user,
        login => 'yanick',
        token => '149c85dddb76ba940531420fa9ca821f',
    );

    for my $p ( @{ $u->list } ) {
        harvest_project( $user, $p->{name} );
        sleep 1;
    }

    push @seen_users, $user;
}



