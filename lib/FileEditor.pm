package FileEditor;
use Dancer2;
use File::Slurp;
use File::Spec;
use Try::Tiny;
use JSON;
use Encode qw(decode_utf8);

set 'template' => 'template_toolkit';
set 'layout' => undef;
set 'charset' => 'UTF-8';

get '/' => sub {
    template 'index', { 
        files => list_files(),
        dancer_version => Dancer2->VERSION,
    };
};

post '/save' => sub {
    my $content = decode_utf8(param('content'));
    my $filename = decode_utf8(param('filename'));
    
    try {
        write_file(File::Spec->catfile('files', $filename), $content);
        send_as JSON => { success => 1, message => "Archivo guardado exitosamente" };
    } catch {
        send_as JSON => { success => 0, message => "Error al guardar el archivo: $_" };
    };
};

get '/open' => sub {
    my $filename = decode_utf8(param('filename'));
    
    try {
        my $content = read_file(File::Spec->catfile('files', $filename));
        send_as JSON => { success => 1, content => $content };
    } catch {
        send_as JSON => { success => 0, message => "Error al abrir el archivo: $_" };
    };
};

get '/list' => sub {
    send_as JSON => { files => list_files() };
};

sub list_files {
    my @files = glob('files/*');
    return [map { (File::Spec->splitpath($_))[2] } @files];
}

true;
