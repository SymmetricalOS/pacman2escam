import haxe.Json;
import sys.io.File;
import sys.FileSystem;

using StringTools;

class Main {
	static function main() {
		var pkg = Sys.args()[0];
		var ver = Sys.args()[1];
		var arch = Sys.args()[2];
		var repo = Sys.args()[3];
		var fn = '$pkg-$ver-$arch.pkg.tar.zst';
		var url = '$repo/$fn';
		Sys.command("rm -r ./tmp");
		Sys.command('wget $url');
		FileSystem.createDirectory("tmp");
		Sys.command('tar -xhf $fn -C ./tmp');
		FileSystem.deleteFile('$fn');

		var dat:Dat = {depends: [], files: [], dirs: []};

		var pkginfo = File.getContent("tmp/.PKGINFO");
		for (line in pkginfo.split("\n")) {
			if (line.startsWith("depend")) {
				dat.depends.push(line.split(" = ")[1]);
			}
		}

		var files = scan("tmp", true);

		for (file in files) {
			dat.files.push(file.substring(3));
		}

		File.saveContent('$pkg-$ver.dat', Json.stringify(dat));

		File.saveContent('$pkg-$ver.install', File.getContent('tmp/.INSTALL'));

		var owd = Sys.getCwd();
		Sys.setCwd("./tmp");
		Sys.command('zip -q -r ../$pkg-$ver.zip *');
		Sys.setCwd(owd);

		Sys.println("Consider packaging the following dependencies:");
		for (dep in dat.depends) {
			Sys.println(dep);
		}
	}

	static function scan(dir:String, ?root:Bool = false):Array<String> {
		var files = [];

		var things = FileSystem.readDirectory(dir);
		for (item in things) {
			// trace('$dir/$item');
			if (FileSystem.isDirectory('$dir/$item'))
				files = files.concat(scan('$dir/$item'));
			else if (!root)
				files.push('$dir/$item');
		}

		return files;
	}
}
