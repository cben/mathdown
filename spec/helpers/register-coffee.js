// Allow writing spec/*.coffee in coffeescript.  Helpers are always loaded before specs.
// [https://github.com/jasmine/jasmine-npm/issues/14]
// If I add any other *helper* in coffeescript, I'd need to list this first in jasmine.json.
require('coffee-script/register');
