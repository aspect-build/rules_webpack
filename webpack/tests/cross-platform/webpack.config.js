// Requiring sharp exercises its native C/C++ addon. If the package was resolved
// for the wrong platform, this will fail when webpack evaluates the config.
require('sharp')

module.exports = {}
