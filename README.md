profitbricks-builder
====================


# encrypted databags

## Description

node.js builder and wrapper for the profitbricks soap api

## Motivation


## Usage


## runninung tests and samples

to not forget to run "npm install" once after checkout

*run mocha tests:*

	./node_modules/.bin/mocha  -R tap --compilers coffee:coffee-script test/soapclient-test.coffee
	./node_modules/.bin/mocha  -R tap --compilers coffee:coffee-script test/profitbricks_jobbuilder-test.coffee

*run samples:*

	# first provide your profitbricks credentials

	# copy the credentials template file to examples/credentials.coffee
	cp examples/credentials_tmpl.coffee examples/credentials.coffee
	#  and config with your profitbricks user and passsword

	DEBUG=* ./node_modules/.bin/coffee examples/create_datacenter.coffee


## development

development is taking place in the coffee files in the src folder. the javascript files are generated into the lib directory with the command:

	cake build


