# version is a human-readable version number.

# http://legacy.python.org/dev/peps/pep-0440/#version-scheme
# Use the pep-0440 as a versioning guidline
# There are always four parts, although trailing parts 'may' be empty.
# Idealy the first 3 parts will always have a value
__version_info__ = ('2', '0', '0')
__version__ = '.'.join(__version_info__)
