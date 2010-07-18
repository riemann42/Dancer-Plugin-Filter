#Revision: $Id$
package Dancer::Plugin::Filter;
use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;

our $VERSION = '0.001';

=head1 NAME

Dancer::Plugin::Filter

=head1 SYNOPSIS
    
    package MyPage;

    use Dancer;
    use Dancer::Plugin::Filter;

    add_filter('image/jpeg', { module => 'MyPage::Image::JPEG', extension => 'jpg' });
    prepare_filters;

    get '/people/:name' => sub {
        return { jpeg => "images/" . params->{name} . ".jpg" , name => params->{name} }
    }

    1;

    package MyPage::Image::JPEG;
    use Dancer::FileUtils qw(path dirname read_file_content);
    use base 'Dancer::Serializer::Abstract';

    sub serialize {
        my ($self,$entity) = @_;
        if (exists $entity->{jpeg}) {
            my $static_file = path(setting('public'), $entity->{jpeg});
            if ( -e  $static_file) {
                open my $fh, "<", $static_file;
                binmode $fh;
                return $fh;
            }
        }
    }

    sub content_type { "image/jpeg" }
    1;


=head1 DESCRIPTION

Dancer plugin to allow the easy creation of custom input and output filters using Dancer's serializer interface. 

This module is essentially a wrapper for Dancer::Serializer::Filter to make implementation more transparent.

See Dancer::Serializer::Filter for more information about the process.

=cut

Dancer::ModuleLoader->load('Dancer::Serializer::Filter') or die "Failied to load Dancer::Serializer::Filter\n"; 

=head1 METHODS

=over 4

=item B<prepare_filters>

Adds path mangaling to remove extensions.

=cut

register prepare_filters => sub {
    before sub {
        set serializer => 'Filter';
        my $ct = Dancer::Serializer::Filter->get_content_types(request);
        if ((exists $ct->{new_path_info}) && ($ct->{new_path_info})) {
            request->path_info($ct->{new_path_info});
        }
    };
};

=item B<add_filter>

Use: add_filter($mimetype, { module => $modulename, extension => $extension });

Adds a filter for $mimetype using module $modulename and extension $extension

=cut

register add_filter => sub {
    Dancer::Serializer::Filter->add_filter(@_);
};

register_plugin;

1;

__END__

=back

=head1 SEE ALSO

L<Dancer|Dancer>, L<Dancer::Serializer::Filter|Dancer::Serializer::Filter>

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

