import sys,re
from os.path import isdir
from importlib import invalidate_caches
from importlib.abc import SourceLoader
from importlib.machinery import FileFinder


class Imp32Loader(SourceLoader):
    pat = re.compile("(?<=[\(\[\=\s])u(?=(\'[^\']*\'|\"[^\"]*\"))")
    def __init__(self, fullname, path):
        self.fullname = fullname
        self.path = path

    def get_filename(self, fullname):
        return self.path

    def get_data(self, filename):
        """
        exec_module is already defined for us, 
        we just have to provide a way of getting 
        the source code of the module
        """
        with open(filename) as f:
            data = f.readlines()
            for l in data:
                l = re.sub(Imp32Loader.pat,"",l)
                #new = re.sub(Imp32Loader.pat,"",l)
                #if(new != l):
                #    print(l+" ==> "+new)
        return "".join(data)

det = Imp32Loader,[".py"]
def installImportOverride():
    # insert the path hook ahead of other path hooks
    sys.path_hooks.insert(0, FileFinder.path_hook(det))
    # clear any loaders that might already be in use by the FileFinder
    sys.path_importer_cache.clear()
    invalidate_caches()

install()
import openpyxl

