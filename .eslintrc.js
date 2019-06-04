module.exports = {
	globals: {
		importScripts: true
	},
	'parserOptions': {
		'ecmaVersion': 8
	},
	env: {
		node: true,
		es6: true
	},
	'ecmaFeatures': {
		'modules': true,
		'arrowFunctions': true,
		'classes': true
	},
	plugins: ['prettier'],
	rules: {
		'no-unused-vars': ['error', { 'vars': 'all', 'args': 'after-used', 'ignoreRestSiblings': false }]
	},
	extends: ['plugin:prettier/recommended']
}
