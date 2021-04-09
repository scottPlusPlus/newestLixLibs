import tink.semver.Version;
import hx.files.*;
import tink.CoreApi;

class Main {
	private static final HAXE_LIBRARIES_DIR = "./haxe_libraries";
	private static final COPIES_DIR = "./haxe_libraries_newest";

	public static function fileMap(dir:Dir):Map<String, File> {
		var res = new Map<String, File>();
		var files = dir.listFiles();
		for (f in files) {
			var name = f.path.filename;
			res.set(name, f);
		}
		return res;
	}

	public static function libVersion(f:File):Outcome<Version, Error> {
		var content = f.readAsString();
		var split = content.split('\n');
		for (line in split) {
			if (!StringTools.contains(line, "-D")) {
				continue;
			}
			var nextSplit = line.split("=");
			var semver = nextSplit[1];
			return Version.parse(semver);
		}
		return Failure(new Error('Could not find a version from file: ${f.path.filename}'));
	}

	public static function libVersionSure(f:File):Version {
		var v = libVersion(f);
		switch (v) {
			case Success(data):
				return data;
			case Failure(failure):
				var errMsg = 'Failed to get version for ${f.path.filename}:  ${failure.message}';
				Sys.println(errMsg);
				throw(errMsg);
		}
	}

	public static function main() {
		var newest_dir = Dir.of(COPIES_DIR);
		if (!newest_dir.path.exists()) {
			newest_dir.create();
		}
		var target_files = fileMap(newest_dir);

		var newest_versions = new Map<String, Version>();
		for (kv in target_files.keyValueIterator()) {
			var version = libVersionSure(kv.value);
			newest_versions.set(kv.key, version);
		}

		var source_dir = Dir.of(HAXE_LIBRARIES_DIR);
		var source_files = source_dir.findFiles("*.hxml");

		var setNewestVersion = function(f:File, v:Version):Void {
			var fname = f.path.filename;
			newest_versions.set(fname, v);
			var p = newest_dir.path.toString();
			p += "./" + fname;
			f.copyTo(p, [OVERWRITE]);
		};

		for (f in source_files) {
			// Sys.println('found ${f.path}');
			var fname = f.path.filename;
			var fileVersion = libVersionSure(f);
			var newestVersion = newest_versions.get(fname);

			if (newestVersion == null || newestVersion < fileVersion) {
				Sys.println('setting newest version of ${fname} = ${fileVersion}');
				setNewestVersion(f, fileVersion);
			} else if (newestVersion > fileVersion) {
				var bestFile = target_files.get(fname);
				if (bestFile == null) {
					continue;
				}
				Sys.println('discarding ${fname} v ${fileVersion} for newer version ${newestVersion}');
				var p = source_dir.path.toString();
				p += "./" + fname;
				bestFile.copyTo(p, [OVERWRITE]);
			} else {
				// if versions are equal, take the local version as it might be newer
				// but do so silently
				setNewestVersion(f, fileVersion);
			}
		}
		Sys.println("done");
	}
}
