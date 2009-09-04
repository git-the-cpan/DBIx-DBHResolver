package DBIx::DBHResolver;

use strict;
use warnings;
use base qw(Class::Data::Inheritable);

__PACKAGE__->mk_classdata('config');
__PACKAGE__->config( +{} );

use Carp;
use DBI;
use UNIVERSAL::require;
use YAML;

our $VERSION = '0.01';

sub load {
    my ( $class, $file ) = @_;

    unless ( -e $file && -r $file ) {
        croak $!;
    }

    $class->config( +{ connect_info => YAML::LoadFile($file) } );
}

sub connect {
    my ( $class, $label, $args ) = @_;
    return DBI->connect( @{ $class->connect_info( $label, $args ) }
          {qw/dsn user password attrs/} );
}

sub connect_cached {
    my ( $class, $label, $args ) = @_;
    return DBI->connect_cached( @{ $class->connect_info( $label, $args ) }
          {qw/dsn user password attrs/} );
}

sub connect_info {
    my ( $class, $label, $args ) = @_;

    if ( ref $args eq 'HASH' ) {
        croak "arguments require 'strategy'" unless $args->{strategy};
        my $strategy_class =
            $args->{strategy} =~ /^\+(.+)$/
          ? $1
          : join( '::', ( __PACKAGE__, 'Strategy', $args->{strategy} ) );

        $strategy_class->require;
        return $strategy_class->connect_info( $class, $label, $args );
    }
    else {
        croak 'not found connect_info'
          unless ( exists $class->config->{connect_info}->{$label} );
        return $class->config->{connect_info}->{$label};
    }
}

sub cluster {
    my ( $class, $cluster_name ) = @_;
    wantarray
      ? @{ $class->config->{clusters}->{$cluster_name} }
      : $class->config->{clusters}->{$cluster_name};
}

1;

__END__

=for stopwords yaml

=head1 NAME

DBIx::DBHResolver - Pluggable library handles many databases a.k.a Database DBHResolver.

=head1 SYNOPSIS

  use DBIx::DBHResolver;

  DBIx::DBHResolver->config(+{
    connect_info => +{
      MASTER => +{
        dsn => 'dbi:mysql:dbname=main;host=master',
        user => 'root',
        password => '',
        attrs => +{ RaiseError => 1, AutoCommit => 0, }
      },
      SLAVE1 => +{
        dsn => 'dbi:mysql:dbname=main;host=slave1',
        user => 'root',
        password => '',
        attrs => +{ RaiseError => 1, AutoCommit => 0, }
      },
      SLAVE2 => +{
        dsn => 'dbi:mysql:dbname=main;host=slave2',
        user => 'root',
        password => '',
        attrs => +{ RaiseError => 1, AutoCommit => 0, }
      },
      HEAVY_MASTER1 => +{
        dsn => 'dbi:mysql:dbname=heavy;host=heavy_master1',
        user => 'root',
        password => '',
        attrs => +{ RaiseError => 1, AutoCommit => 0, }
      },
      HEAVY_MASTER2 => +{
        dsn => 'dbi:mysql:dbname=heavy;host=heavy_master2',
        user => 'root',
        password => '',
        attrs => +{ RaiseError => 1, AutoCommit => 0, }
      },
    },
    cluster => +{
      SLAVE => [ qw/SLAVE1 SLAVE2/ ],
      HEAVY_MASTER => [ qw/HEAVY_MASTER1 HEAVY_MASTER2/ ]
    },
  });

  my $master_conn_info = DBIx::DBHResolver->connect_info('MASTER');
  my $master_dbh       = DBIx::DBHResolver->connect('MASTER');

  my ($even_num, $odd_num) = (100, 101);

  ### Using DBIx::DBHResolver::Strategy::Simple
  my $heavy_cluster_list = DBIx::DBHResolver->cluster('HEAVY_MASTER');
  my $heavy1_conn_info   = DBIx::DBHResolver->connect_info('HEAVY_MASTER', +{ strategy => 'Simple', key => $even_num });
  my $heavy2_dbh         = DBIx::DBHResolver->connect_cached('HEAVY_MASTER', +{ strategy => 'Simple', key => $odd_num });

  ### Using DBIx::DBHResolver::Strategy::RoundRobin
  my $slave_dbh          = DBIx::DBHResolver->connect('SLAVE', +{ strategy => 'RoundRobin' });

=head1 DESCRIPTION

DBIx::DBHResolver is pluggable library handles many databases as known as Database DBHResolver Approach.

It can retrieve L<DBI>'s database handle object or connection information (data source, user, credential...) by labeled name using connect(), connect_cached(), connect_info() method,
and treat same cluster consists many nodes as one labeled name, choose fetching strategy.

DBHResolver strategy is pluggable, so you can make custom strategy easily.

=head1 METHODS

=head2 load($yaml_file_path)

Load config file formatted yaml.

=head2 config(\%config)

Load config. (See SYNOPSIS)

=head2 connect($label, \%args)

Retrieve database handle. see below about \%args details.

=over

=item strategy

Specify strategy module name suffix. Default strategy module is prefixed 'DBIx::DBHResolver::Strategy::'.
If you want to make custom strategy not prefixed 'DBIx::DBHResolver::Strategy::', add '+' prefixed module name such as '+MyApp::Strategy::Custom'.

=item key

Strategy module uses hint choosing node.

=back

=head2 connect_cached($label, \%args)

Retrieve database handle using DBI::connect_cached(). \%args is same as connect().

=head2 connect_info($label, \%args)

Retrieve connection info as HASHREF. \%args is same as connect().

=head2 cluster($cluster_name)

Retrieve cluster member node names as Array.

=head1 AUTHOR

Kosuke Arisawa E<lt>arisawa@gmail.comE<gt>

Toru Yamaguchi E<lt>zigorou@cpan.orgE<gt>

=head1 SEE ALSO

=over

=item L<DBI>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut