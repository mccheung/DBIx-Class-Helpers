package DBIx::Class::Helper::JoinTable;

sub _guess_namespace {
   my $self = shift;
   if ($self =~ m/([A-Za-z0-9_:]+)::Result::[A-Za-z0-9_]+/) {
      return $1;
   } else {
      die "$self doesn't look like".'${namespace}::Result::$resultclass';
   }
}

sub join_table {
   my $self   = shift;
   my $params = shift;
   $params->{namespace} ||= $self->_guess_namespace;
   $self->set_table($params);
   $self->add_join_columns($params);
   $self->generate_relationships($params);
   $self->generate_primary_key($params);
}

sub generate_primary_key {
   my ($self, $params) = @_;
   $self->set_primary_key("$params->{left_method}_id", "$params->{right_method}_id");
}

sub generate_relationships {
   my ($self, $params) = @_;
   $params->{namespace} ||= $self->_guess_namespace;
   $self->belongs_to(
      $params->{left_method} =>
      "$params->{namespace}::Result::$params->{left_class}",
      "$params->{left_method}_id"
   );
   $self->belongs_to(
      $params->{right_method} =>
      "$params->{namespace}::Result::$params->{right_class}",
      "$params->{right_method}_id"
   );
}

sub set_table {
   my ($self, $params) = @_;
   $self->table("$params->{left_class}_$params->{right_class}");
}

sub add_join_columns {
   my ($self, $params) = @_;
   $self->add_columns(
      "$params->{left_method}_id" => {
         data_type         => 'integer',
         is_nullable       => 0,
         is_numeric        => 1,
      },
      "$params->{right_method}_id" => {
         data_type         => 'integer',
         is_nullable       => 0,
         is_numeric        => 1,
      },
   );
}

1;

=pod

=head1 SYNOPSIS

 package MyApp::Schema::Result::Foo_Bar;

 __PACKAGE__->load_components(qw{Helper::JoinTable Core});

 __PACKAGE__->join_table({
    left_class   => 'Foo',
    left_method  => 'foo',
    right_class  => 'Bar',
    right_method => 'bar',
 });

 # the above is the same as:

 __PACKAGE__->table('Foo_Bar');
 __PACKAGE__->add_columns(
    foo_id => {
       data_type         => 'integer',
       is_nullable       => 0,
       is_numeric        => 1,
    },
    bar_id => {
       data_type         => 'integer',
       is_nullable       => 0,
       is_numeric        => 1,
    },
 );

 $self->set_primary_key(qw{foo_id bar_id});

 __PACKAGE__->belongs_to( foo => 'MyApp::Schema::Result::Foo' 'foo_id');
 __PACKAGE__->belongs_to( bar => 'MyApp::Schema::Result::Bar' 'bar_id');

=head1 METHODS

All the methods take a configuration hashref that looks like the following:
 {
    left_class   => 'Foo',
    left_method  => 'foo',
    right_class  => 'Bar',
    right_method => 'bar',
    namespace    => 'MyApp', # default is guessed via *::Result::Foo
 }

=head2 join_table

This is the method that you probably want.  It will set your table, add
columns, set the primary key, and set up the relationships.

=head2 add_join_columns

Adds two non-nullable integer fields named C<"${left_method}_id"> and
C<"${right_method}_id"> respectively.

=head2 generate_primary_key

Sets C<"${left_method}_id"> and C<"${right_method}_id"> to be the primary key.

=head2 generate_relationships

This adds relationships to C<"${namespace}::Schema::Result::$left_class"> and
C<"${namespace}::Schema::Result::$left_class"> respectively.

=head2 set_table

This method sets the table to "${left_class}_${right_class}".

