

from setuptools import setup
from setuptools.command.build_py import build_py
import ctypes.util
import subprocess
import os


with open('README.md') as f:
    long_description = f.read()


class BuildPyCommand(build_py):
    """Custom build command."""

    def run(self):
        # check if libquiet.so is at system lib paths
        if not ctypes.util.find_library('quiet'):
            libquiet = os.path.join(os.path.dirname(
                __file__), 'quiet', 'libquiet.so')
            if not os.path.isfile(libquiet):
                # build libquiet.so
                subprocess.check_call(['bash', 'scripts/libs.sh'])

        build_py.run(self)


setup(name='quiet.py',
      version='0.1',
      description='Quiet Modem, to transmit data with sound',
      long_description=long_description,
      long_description_content_type='text/markdown',
      author='Brian Armstrong, Yihui Xiong',
      author_email='brian.armstrong.ece+pypi@gmail.com',
      url='https://github.com/quiet/quiet.py',
      cmdclass={
          'build_py': BuildPyCommand,
      },
      packages=['quiet'],
      include_package_data=True,
      install_requires=['numpy'],
      zip_safe=False)
