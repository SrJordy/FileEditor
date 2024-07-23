package FileEditor;
use Dancer2;
use File::Slurp;
use File::Spec;
use Try::Tiny;
use JSON;
use Encode qw(decode_utf8);
use File::HomeDir;  # Módulo para obtener la ruta de la carpeta de inicio del usuario
use File::Path qw(make_path);

set 'template' => 'template_toolkit';
set 'layout' => undef;
set 'charset' => 'UTF-8';

# Obtén la ruta de la carpeta de Descargas y define la subcarpeta
my $downloads_folder = File::Spec->catdir(File::HomeDir->my_home, 'Downloads');
my $editor_folder = File::Spec->catdir($downloads_folder, 'EditorArchivos');

# Crea la subcarpeta si no existe
unless (-d $editor_folder) {
    make_path($editor_folder);
}

get '/' => sub {
    template 'index', { 
        files => list_files(),
        dancer_version => Dancer2->VERSION,
    };
};

post '/save' => sub {
    my $content = decode_utf8(param('content'));
    my $filename = decode_utf8(param('filename'));
    my $is_editing = param('is_editing') || 0;

    my $file_path = File::Spec->catfile($editor_folder, $filename);

    # Validación para archivos repetidos
    if (-e $file_path && !$is_editing) {
        send_as JSON => { success => 0, message => "El archivo ya existe. Para modificarlo, usa la opción de edición." };
        return;
    }

    try {
        write_file($file_path, $content);
        send_as JSON => { success => 1, message => "Archivo guardado exitosamente" };
    } catch {
        send_as JSON => { success => 0, message => "Error al guardar el archivo: $_" };
    };
};

get '/open' => sub {
    my $filename = decode_utf8(param('filename'));
    my $file_path = File::Spec->catfile($editor_folder, $filename);

    try {
        my $content = read_file($file_path);
        send_as JSON => { success => 1, content => $content };
    } catch {
        send_as JSON => { success => 0, message => "Error al abrir el archivo: $_" };
    };
};

get '/list' => sub {
    send_as JSON => { files => list_files() };
};

sub list_files {
    my @files = glob(File::Spec->catfile($editor_folder, '*'));
    return [map { (File::Spec->splitpath($_))[2] } @files];
}

true;
