import haxe.io.Path;
import haxe.Json;
import sys.io.File;
import sys.FileSystem;

using StringTools;

class Main {
	static function main() {
		var path = Path.removeTrailingSlashes(Sys.args()[0]);
		var dirs = FileSystem.readDirectory(path);

		for (dir in dirs) {
			var file = File.getContent('./$path/$dir/desc');

			var pkg = "";
			var ver = "";
			var arch = "";

			var prevline = "";
			for (line in file.split("\n")) {
				if (prevline.contains("%NAME%")) {
					pkg = line;
				}
				if (prevline.contains("%VERSION%")) {
					ver = line;
				}
				if (prevline.contains("%ARCH%")) {
					arch = line;
				}

				prevline = line;
			}

			if (!ver.contains(":") && !file.contains("tar.xz")) {
				compute(pkg, ver, arch, path);
			}
		}
	}

	static function compute(pkg:String, ver:String, arch:String, r:String) {
		var repo = 'https://forksystems.mm.fcix.net/archlinux/$r/os/x86_64';
		var fn = '$pkg-$ver-$arch.pkg.tar.zst';
		var url = '$repo/$fn';
		Sys.command("sudo rm -rf ./tmp");
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

		File.saveContent('$pkg--$ver.dat', Json.stringify(dat));

		if (FileSystem.exists("tmp/.INSTALL")) {
			File.saveContent('$pkg--$ver.install', File.getContent('tmp/.INSTALL') + "\n\n\n\"$@\"");
		}

		var owd = Sys.getCwd();
		Sys.setCwd("./tmp");
		Sys.command('zip -q -r ../$pkg--$ver.zip *');
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
