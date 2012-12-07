#Revision: $Id$
package Dancer::Serializer::Filter;
use strict;
use warnings;
use Dancer::SharedData;
use Data::Dumper;

our $VERSION = 0.02;

use base 'Dancer::Serializer::Abstract';

=head1 NAME

Dancer::Serializer::Filter

=head1 SYNOPSIS

=head1 DESCRIPTION

Serializer for creating output filters based on accepted mime_type or extension and input based on content_type.

This is for use with the plugin Dancer::Plugin::Filter, but can be used on it's own.

=cut

{

    my $serializer = { 'text/x-yaml'      => { module => 'Dancer::Serializer::YAML', extension => 'yaml' },
                       'txt/xml'          => { module => 'Dancer::Serializer::XML',  extension => 'xml' },
                       'application/json' => { module => 'Dancer::Serializer::JSON', extension => 'json' },
                       'text/x-json'      => { module => 'Dancer::Serializer::JSON', extension => 'JSON' },
                     };

    my $default_content_type = q{};

    sub _set_content_types {
        my $self = shift;
        my $request = shift || Dancer::SharedData->request;
        if ( !$request ) {
            Dancer::debug("No Request Object!?!?");
            return;
        }
        Dancer::SharedData->vars->{content_type_out} = undef;
        Dancer::SharedData->vars->{content_type_in}  = undef;
        Dancer::SharedData->vars->{new_path_info}    = undef;

        for my $mime_type ( keys %{$serializer} ) {
            if ( $request->content_type =~ /^$mime_type/xms ) {
                Dancer::SharedData->vars->{content_type_in} = $mime_type;
            }
            if ( $request->accept =~ /^$mime_type/xms ) { Dancer::SharedData->vars->{content_type_out} = $mime_type; }
        }

        my $match = join( q{|}, map { $serializer->{$_}->{extension} } keys %{$serializer} );
        my %extensions = map { $serializer->{$_}->{extension} => $_ } keys %{$serializer};
        if ( $request->path =~ m{^(.*?)\.($match)$}xms ) {
            my ( $page, $type ) = ( $1, $2 );
            my $mime_type = $extensions{ lc($type) };
            if ($mime_type) {
                Dancer::SharedData->vars->{content_type_out} = $mime_type;
                Dancer::SharedData->vars->{new_path_info}    = $page;
                Dancer::SharedData->vars->{path_extension}   = lc($type);
            }
        }
        return Dancer::SharedData->vars;
    }

=head1 METHODS

=over 4

=cut

=item B<get_content_types>

Use:  Dancer::Serializers::Filter->get_content_types($request)

Processes the request object.  Returns the following hash:
   
   { content_type_out => 'some/format',
     content_type_in => 'some/format',
     new_path_info => 'path/without/extension',
   }

Also sets the Dancer shared vars for each of the above.

=cut

    sub get_content_types {
        my $self    = shift;
        my $request = shift;
        if ( !exists Dancer::SharedData->vars->{content_type_in} ) {
            $self->_set_content_types($request);
        }
        return { content_type_out => Dancer::SharedData->vars->{content_type_out},
                 content_type_in  => Dancer::SharedData->vars->{content_type_in},
                 new_path_info    => Dancer::SharedData->vars->{new_path_info},
               };
    }

=item B<add_filter>

Use: Dancer::Serializer::Filter->add_filter($mimetype, { module => $modulename, extension => $extension });

Adds a filter for $mimetype using module $modulename and extension $extension

=cut

    sub add_filter {
        my $self     = shift;
        my $mimetype = shift;
        my $params   = shift;
        $serializer->{$mimetype} = $params;
        return;
    }

    my $_loaded_modules = {};

    sub _get_filter {
        my $self     = shift;
        my $mimetype = shift;
        return if ( not exists $serializer->{$mimetype} );
        if ( ! exists $_loaded_modules->{$mimetype} ) {
            if ( ref $serializer->{$mimetype}->{module} ) {
                $_loaded_modules->{$mimetype} = $serializer->{$mimetype}->{module};
            }
            else {
                my $module = $serializer->{$mimetype}->{module};
                if ( Dancer::ModuleLoader->load($module) ) {
                    $_loaded_modules->{$mimetype} = $module->new;
                }
            }
        }
        return $_loaded_modules->{$mimetype};
    }

=item B<serialize>

Serialize a data structure based on accept or extension

=cut

    sub serialize {
        my ( $self, $entity ) = @_;
        my $ct = $self->get_content_types();
        if ( $ct->{content_type_out} ) {
            my $s = $self->_get_filter( $ct->{content_type_out} );
            if ($s) {
                return $s->serialize($entity);
            }
            else {
                use Data::Dumper;
                Dancer::debug( "Bad request for type ", $ct->{content_type_out} ."\n" . Dumper($serializer) );

            }
        }
        return;
    }

=item B<deserialize>

Deserialize a data structure based on content_type

=cut

    sub deserialize {
        my ( $self, $content ) = @_;
        my $ct = $self->get_content_types();
        if ( $ct->{content_type_in} ) {
            my $s = $self->_get_filter( $ct->{content_type_in} );
            if ($s) {
                my $test = $s->deserialize($content);
                return $test;
            }
        }
        return;
    }

=item B<content_type>

returns last used content_type or $Dancer::Serializer::Filter::default_content_type

=cut

    sub content_type {
        my $self = shift;
        my $ct   = $self->get_content_types();
        if ( exists $ct->{content_type_out} ) {
            return $ct->{content_type_out};
        }
        else {
            return $default_content_type;
        }
    }

=item B<support_content_type>

Indicates if a filter is loaded for the given content_type.

=cut

    sub support_content_type {
        my ( $self, $ct ) = @_;
        foreach ( keys %{$serializer} ) {
            if ( $ct =~ /$_/xms ) {
                return 1;
            }
        }
        return 0;
    }

}
1;
__END__

=back

=head1 SEE ALSO

L<Dancer|Dancer>, L<Dancer::Plugin::Filter|Dancer::Plugin::Filter>

=head1 AUTHOR

Edward Allen III <ealleniii _at_ cpan _dot_ org>

=head1 COPYRIGHT

Copyright (c) 2007,2008 Edward Allen III. Some rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either:

a) the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

b) the "Artistic License" which comes with Perl.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
Kit, in the file named "Artistic".  If not, I'll be glad to provide one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301, USA or visit their web page on the Internet at
http://www.gnu.org/copyleft/gpl.html.

=cut


