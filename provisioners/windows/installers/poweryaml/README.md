PowerYaml
=========

PowerYaml is a wrapper around [Yaml.Net][] library which is the best .Net Yaml parser I've found so far.

Sample
------

Paste the following into a *sample.yml* file

	parent: 
	  child:
		a: a value
		b: b value
		c: c value
	  child2: 
		key4: value 4
		key5: value 5

And here's the parsing of the above yaml		
		
	PS C:\dev\PowerYaml> Import-Module .\PowerYaml.psm1
    PS C:\dev\PowerYaml> $yaml = Get-Yaml -FromFile (Resolve-Path .\sample.yml)
    PS C:\dev\PowerYaml> $yaml.parent.child

	Name                           Value
	----                           -----
	a                              a value
	b                              b value
	c                              c value

[Yaml.Net]: http://sourceforge.net/projects/yamldotnet/ "Yaml.Net"
