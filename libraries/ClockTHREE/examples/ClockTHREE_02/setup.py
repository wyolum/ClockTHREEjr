# A very simple setup script to create 2 executables.
#
# hello.py is a simple "hello, world" type program, which alse allows
# to explore the environment in which the script runs.
#
# test_wx.py is a simple wxPython program, it will be converted into a
# console-less program.
#
# If you don't have wxPython installed, you should comment out the
#   windows = ["test_wx.py"]
# line below.
#
#
# Run the build process by entering 'setup.py py2exe' or
# 'python setup.py py2exe' in a console prompt.
#
# If everything works well, you should find a subdirectory named 'dist'
# containing some files, among them hello.exe and test_wx.exe.


from distutils.core import setup
import py2exe
import glob

dat_files = ['ClockTHREE_02.pde']
dat_files.extend(glob.glob("../../*.cpp"))
dat_files.extend(glob.glob("../../*.h"))
dat_files.append("8x8.txt")
dat_files.append("README.txt")
setup(
    # The first three parameters are not required, if at least a
    # 'version' is given, then a versioninfo resource is built from
    # them and added to the executables.
    version = "0.0.1_alpha",
    description = "py2exe C3_GUI",
    name = "py2exe C3_GUI",
    data_files = dat_files,
    # targets to build
    # windows = ["WordClockSet.py"],
    windows = ["C3_GUI.py", "ClockTHREE.py"],
    console = ["C3_interface.py"],
    )
