//     ExpressionView - A package to visualize biclusters
//     Copyright (C) 2009 Computational Biology Group, University of Lausanne
// 
//     This program is free software: you can redistribute it and/or modify
//     it under the terms of the GNU General Public License as published by
//     the Free Software Foundation, either version 3 of the License, or
//     (at your option) any later version.
// 
//     This program is distributed in the hope that it will be useful,
//     but WITHOUT ANY WARRANTY; without even the implied warranty of
//     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//     GNU General Public License for more details.
// 
//     You should have received a copy of the GNU General Public License
//     along with this program.  If not, see <http://www.gnu.org/licenses/>.

package ch.unil.cbg.ExpressionView.model {
	
	import __AS3__.vec.Vector;
	
	import ch.unil.cbg.ExpressionView.events.*;
	import ch.unil.cbg.ExpressionView.utilities.LargeBitmapData;
	
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import mx.collections.XMLListCollection;
	import mx.controls.Alert;
	import mx.utils.Base64Decoder;
		
	[Event(name=UpdateStatusBarEvent.UPDATESTATUSBAREVENT, type="ch.unil.cbg.expressionview.events.UpdateStatusBarEvent")];
	[Event(name=GEDCompleteEvent.GEDCOMPLETEEVENT, type="ch.unil.cbg.expressionview.events.GEDCcmpleteEvent")];
	public class GeneExpressionData extends EventDispatcher {
		
		public var nModules:int;
		public var Modules:XMLListCollection;

		public var nGenes:int;
		public var nSamples:int;

		private var separator:String;
		
		public var XMLData:XML;
		// true if data is derived from gene expression matrix
		public var dataOrigin:Boolean;
		public var xAxisLabel:String;
		public var yAxisLabel:String;
		
		public var geneLabels:Vector.<Array>;
		public var sampleLabels:Vector.<Array>;
		public var moduleLabels:Vector.<Array>;
		public var goLabels:Vector.<Array>;
		public var keggLabels:Vector.<Array>;
		private var keggs:XMLListCollection;
		private var gos:XMLListCollection;		
		
		public var ModulesColors:Vector.<Array>;

		private var Data:ByteArray;
		private var ModularData:Vector.<GeneExpressionModule>;
		
		private var gebitmapdata:LargeBitmapData;
		private var modulesbitmapdata:LargeBitmapData;
		
		private var ModulesLookup:Vector.<Array>;
		public var ModulesLookupGenes:Vector.<Array>;
		public var ModulesLookupSamples:Vector.<Array>;
		public var ModulesLookupModules:Vector.<Array>;
		public var ModulesLookupGOs:Vector.<Array>;
		public var ModulesLookupGOsP:Vector.<Array>;
		public var ModulesLookupKEGGs:Vector.<Array>;
		public var ModulesLookupKEGGsP:Vector.<Array>;
		
		public var GenesLookup:Vector.<Array>;
		// inverted
		public var GenesLookupP:Vector.<Array>;
		public var SamplesLookup:Vector.<Array>;
		// inverted
		public var SamplesLookupP:Vector.<Array>;
				
		public function GeneExpressionData() {
			super();
			nModules = 0;
			Modules = new XMLListCollection();

			nGenes = 0;
			nSamples = 0;
			
			dataOrigin = true;
			xAxisLabel = "Genes";
			yAxisLabel = "Samples";
					
			XMLData = new XML();
			Data = new ByteArray();
			
			ModularData = new Vector.<GeneExpressionModule>();
												
			ModulesLookup = new Vector.<Array>();
			ModulesLookupGenes = new Vector.<Array>();
			ModulesLookupSamples = new Vector.<Array>();
			ModulesLookupModules = new Vector.<Array>();
			ModulesLookupGOs = new Vector.<Array>();
			ModulesLookupKEGGs = new Vector.<Array>();
			
			GenesLookup = new Vector.<Array>();
			GenesLookupP = new Vector.<Array>();
			SamplesLookup = new Vector.<Array>();
			SamplesLookupP = new Vector.<Array>();
		}


		public function initialize(data:XML): void {		

			XMLData = data;
			//XML.ignoreWhitespace = true;

			// Check version and dispatch
			var version:String = XMLData.summary.version;
			
			if (version == "1.0") {
			  initialize_1_0();
			} else if (version == "1.1") {
			  initialize_1_1();
                        } else {
                          // TODO: error, we try to parse anyway
                          initialize_1_1();
                        }
		}
		
		private function initialize_1_0(): void {

		        separator = ", ";

			// read summary
			nModules = int(XMLData.summary.nmodules);
			nGenes = int(XMLData.summary.ngenes);
			nSamples = int(XMLData.summary.nsamples);
			
			dataOrigin = ( XMLData.summary.dataorigin == "non-eisa" ) ? false : true;
			if ( !dataOrigin ) {
				var alert:String = "Data is not derived from a BioConductor ExpressSet. ";
				alert += "Since ExpressionView is designed to explore gene expression data, ";
				alert += "you might encounter unexpected behavior." 
				Alert.show(alert , 'Warning', mx.controls.Alert.OK)
			}
			
			var label:String = XMLData.summary.xaxislabel;
			if ( label != "" ) {
				xAxisLabel = label;
			}
			label = XMLData.summary.yaxislabel;
			if ( label != "" ) {
				yAxisLabel = label;
			}			

			// read expression matrix
			var decoder:Base64Decoder = new Base64Decoder();
			decoder.decode(XMLData.data);
			Data = decoder.toByteArray();
						
			Modules = new XMLListCollection(XMLData.modules.module);
			ModularData = new Vector.<GeneExpressionModule>(nModules+1, true);
			ModulesColors = new Vector.<Array>(nModules+1, true);
			for ( var module:int = 0; module <= nModules; ++module ) {
				ModularData[module] = new GeneExpressionModule();
				ModulesColors[module]  = [hsv2rgb(module / nModules * 360, 100, 60), hsv2rgb(module / nModules * 360, 100, 100)];
			}

			// read labels
			var tags:XML = XML(XMLData.genes.genetags);
			var size:int = tags.children().length();
			geneLabels = new Vector.<Array>(size, true);
 			for ( var tag:int = 0; tag < size; ++tag ) {
 				var temp:String = tags.children()[tag].name();
				geneLabels[tag] = [temp, tags.child(temp)];
			}
			tags = new XML(XMLData.samples.sampletags);
			size = tags.children().length();
			sampleLabels = new Vector.<Array>(size, true);
 			for ( tag = 0; tag < size; ++tag ) {
 				temp = tags.children()[tag].name();
				sampleLabels[tag] = [temp, tags.child(temp)];
			}
			tags = new XML(XMLData.modules.moduletags);
			size = tags.children().length();
			moduleLabels = new Vector.<Array>(size, true);
 			for ( tag = 0; tag < size; ++tag ) {
 				temp = tags.children()[tag].name();
				moduleLabels[tag] = [temp, tags.child(temp)];
			}
			goLabels = new Vector.<Array>;
			if ( XMLData.modules.child("gotags").length() > 0 ) {
				tags = new XML(XMLData.modules.gotags);
				size = tags.children().length();
				goLabels = new Vector.<Array>(size, true);
	 			for ( tag = 0; tag < size; ++tag ) {
 					temp = tags.children()[tag].name();
					goLabels[tag] = [temp, tags.child(temp)];
				}
			}
			keggLabels = new Vector.<Array>;
			if ( XMLData.modules.child("keggtags").length() > 0 ) {
				tags = new XML(XMLData.modules.keggtags);
				size = tags.children().length();
				keggLabels = new Vector.<Array>(size, true);
 				for ( tag = 0; tag < size; ++tag ) {
 					temp = tags.children()[tag].name();
					keggLabels[tag] = [temp, tags.child(temp)];
				}
			}

			ModulesLookupGOs = new Vector.<Array>(nModules+1, true);
			ModulesLookupGOsP = new Vector.<Array>(nModules+1, true);
			gos = new XMLListCollection();
			var tempsort:Array = [];
			for ( module = 1; module <= nModules; ++module ) {
				var length:int = XMLData.modules.module[module-1].gos.go.length();
				ModulesLookupGOs[module] = new Array(length+1);
				ModulesLookupGOsP[module] = new Array(length);
				for ( var i:int = 0; i < length; ++i ) {
					tempsort.push(new Object());
					var item:XML = new XML(XMLData.modules.module[module-1].gos.go[i]);
					tempsort[tempsort.length-1].pvalue = item.pvalue;
					tempsort[tempsort.length-1].module = module;
					tempsort[tempsort.length-1].slot = i+1;
					item.id = gos.length + 1; 
					gos.addItem(item);
				}
			}
			ModulesLookupGOs[0] = [];
			for ( i = 0; i < gos.length; ++i ) {
				module = tempsort[i].module;
				ModulesLookupGOs[module][tempsort[i].slot] = i+1;
				ModulesLookupGOsP[module][i.toString()] = tempsort[i].slot - 1; 
				ModulesLookupGOs[0].push(module);
			} 
			
			ModulesLookupKEGGs = new Vector.<Array>(nModules+1, true);
			ModulesLookupKEGGsP = new Vector.<Array>(nModules+1, true);
			keggs = new XMLListCollection();
			tempsort = [];
			for ( module = 1; module <= nModules; ++module ) {
				length = XMLData.modules.module[module-1].keggs.kegg.length();
				ModulesLookupKEGGs[module] = new Array(length+1);
				ModulesLookupKEGGsP[module] = new Array(length);
				for ( i = 0; i < length; ++i ) {
					tempsort.push(new Object());
					item = new XML(XMLData.modules.module[module-1].keggs.kegg[i]);
					tempsort[tempsort.length-1].pvalue = item.pvalue;
					tempsort[tempsort.length-1].module = module;
					tempsort[tempsort.length-1].slot = i+1;
					item.id = keggs.length + 1; 
					keggs.addItem(item);
				}
			}
			ModulesLookupKEGGs[0] = [];
			for ( i = 0; i < keggs.length; ++i ) {
				module = tempsort[i].module;
				ModulesLookupKEGGs[module][tempsort[i].slot] = i+1;
				ModulesLookupKEGGsP[module][i.toString()] = tempsort[i].slot - 1;
				ModulesLookupKEGGs[0].push(module);
			}

			// set modularData[0]
			ModularData[0].nGenes = nGenes;
			ModularData[0].Genes = new XMLListCollection(XMLData.genes.gene);
			ModularData[0].nSamples = nSamples;
			ModularData[0].Samples = new XMLListCollection(XMLData.samples.sample);
			ModularData[0].GO = new XMLListCollection(gos.source);
			ModularData[0].KEGG = new XMLListCollection(keggs.source);

			ModulesLookup = new Vector.<Array>(nGenes * nSamples, true);
			for ( i = 0; i < ModulesLookup.length; ++i ) { ModulesLookup[i] = []; }
			
			ModulesLookupGenes = new Vector.<Array>(nGenes+1, true);
			for ( i = 0; i < ModulesLookupGenes.length; ++i ) { ModulesLookupGenes[i] = []; }

			ModulesLookupSamples = new Vector.<Array>(nSamples+1, true);
			for ( i = 0; i < ModulesLookupSamples.length; ++i ) { ModulesLookupSamples[i] = []; }

			ModulesLookupModules = new Vector.<Array>(nModules+1, true);
			for ( i = 0; i < ModulesLookupModules.length; ++i ) { ModulesLookupModules[i] = []; }

			GenesLookup = new Vector.<Array>(nModules+1, true);
			GenesLookupP = new Vector.<Array>(nModules+1, true);
			SamplesLookup = new Vector.<Array>(nModules+1, true);
			SamplesLookupP = new Vector.<Array>(nModules+1, true);			
			ModularData[0].ModulesRectangles = new Vector.<Array>(nModules+1, true);
			ModularData[0].ModulesOutlines = new Vector.<int>(nModules+1, true);

			setTimeout(treatModules, 10, 1);
			
		}

		private function recode(list:XMLListCollection): XMLListCollection {
		  for (var i:int = 0; i<list.length; i++) {
		    for (var j:int = 0; j<list[i].children().length(); j++) {
                      var name:String = list[i].children()[j].name();
                      if (name == "x") {
//		        Alert.show(name + list[i].children()[j].@name, "Warning", mx.controls.Alert.OK);
                        list[i].children()[j].setName(list[i].children()[j].@name);
                      }
                    }
		  }
		  return list;
		}

		private function initialize_1_1(): void {

		        separator = " ";

			// read summary
			nModules = int(XMLData.summary.nmodules);
			nGenes = int(XMLData.summary.ngenes);
			nSamples = int(XMLData.summary.nsamples);
			
			dataOrigin = ( XMLData.summary.dataorigin == "non-eisa" ) ? false : true;
			if ( !dataOrigin ) {
				var alert:String = "Data is not derived from a BioConductor ExpressSet. ";
				alert += "Since ExpressionView is designed to explore gene expression data, ";
				alert += "you might encounter unexpected behavior." 
				Alert.show(alert , 'Warning', mx.controls.Alert.OK)
			}
			
			var label:String = XMLData.summary.xaxislabel;
			if ( label != "" ) {
				xAxisLabel = label;
			}
			label = XMLData.summary.yaxislabel;
			if ( label != "" ) {
				yAxisLabel = label;
			}			

			// read expression matrix
			var decoder:Base64Decoder = new Base64Decoder();
			decoder.decode(XMLData.data);
			Data = decoder.toByteArray();
						
			Modules = recode(new XMLListCollection(XMLData.modules.module));
			ModularData = new Vector.<GeneExpressionModule>(nModules+1, true);
			ModulesColors = new Vector.<Array>(nModules+1, true);
			for ( var module:int = 0; module <= nModules; ++module ) {
				ModularData[module] = new GeneExpressionModule();
				ModulesColors[module]  = [hsv2rgb(module / nModules * 360, 100, 60), hsv2rgb(module / nModules * 360, 100, 100)];
			}

			// read labels
			var tags:XML = XML(XMLData.genes.genetags);
			var size:int = tags.children().length();
			geneLabels = new Vector.<Array>(size, true);
 			for ( var tag:int = 0; tag < size; ++tag ) {
			      	var mytag:Object = tags.children()[tag];
 				var temp:String = mytag.name()
				if (temp != "x") {
				  geneLabels[tag] = [temp, tags.child(temp)];
 				} else {
				  geneLabels[tag] = [mytag.@name, mytag.children()[0]];
                                }
			}
			tags = new XML(XMLData.samples.sampletags);
			size = tags.children().length();
			sampleLabels = new Vector.<Array>(size, true);
 			for ( tag = 0; tag < size; ++tag ) {
			        mytag = tags.children()[tag];
 				temp = mytag.name();
				if (temp != "x") {				  
				  sampleLabels[tag] = [temp, tags.child(temp)];
				} else {
				  sampleLabels[tag] = [mytag.@name, mytag.children()[0]];
 				}
			}
			tags = new XML(XMLData.modules.moduletags);
			size = tags.children().length();
			moduleLabels = new Vector.<Array>(size, true);
 			for ( tag = 0; tag < size; ++tag ) {
			        mytag = tags.children()[tag];
 				temp = mytag.name();
				if (temp != "x") {
				  moduleLabels[tag] = [temp, tags.child(temp)];
 				} else {
				  moduleLabels[tag] = [mytag.@name, mytag.children()[0]];
				}
			}
			goLabels = new Vector.<Array>;
			if ( XMLData.modules.child("gotags").length() > 0 ) {
				tags = new XML(XMLData.modules.gotags);
				size = tags.children().length();
				goLabels = new Vector.<Array>(size, true);
	 			for ( tag = 0; tag < size; ++tag ) {
 					temp = tags.children()[tag].name();
					goLabels[tag] = [temp, tags.child(temp)];
				}
			}
			keggLabels = new Vector.<Array>;
			if ( XMLData.modules.child("keggtags").length() > 0 ) {
				tags = new XML(XMLData.modules.keggtags);
				size = tags.children().length();
				keggLabels = new Vector.<Array>(size, true);
 				for ( tag = 0; tag < size; ++tag ) {
 					temp = tags.children()[tag].name();
					keggLabels[tag] = [temp, tags.child(temp)];
				}
			}

			ModulesLookupGOs = new Vector.<Array>(nModules+1, true);
			ModulesLookupGOsP = new Vector.<Array>(nModules+1, true);
			gos = new XMLListCollection();
			var tempsort:Array = [];
			for ( module = 1; module <= nModules; ++module ) {
				var length:int = XMLData.modules.module[module-1].gos.go.length();
				ModulesLookupGOs[module] = new Array(length+1);
				ModulesLookupGOsP[module] = new Array(length);
				for ( var i:int = 0; i < length; ++i ) {
					tempsort.push(new Object());
					var item:XML = new XML(XMLData.modules.module[module-1].gos.go[i]);
					tempsort[tempsort.length-1].pvalue = item.pvalue;
					tempsort[tempsort.length-1].module = module;
					tempsort[tempsort.length-1].slot = i+1;
					item.id = gos.length + 1; 
					gos.addItem(item);
				}
			}
			ModulesLookupGOs[0] = [];
			for ( i = 0; i < gos.length; ++i ) {
				module = tempsort[i].module;
				ModulesLookupGOs[module][tempsort[i].slot] = i+1;
				ModulesLookupGOsP[module][i.toString()] = tempsort[i].slot - 1; 
				ModulesLookupGOs[0].push(module);
			} 
			
			ModulesLookupKEGGs = new Vector.<Array>(nModules+1, true);
			ModulesLookupKEGGsP = new Vector.<Array>(nModules+1, true);
			keggs = new XMLListCollection();
			tempsort = [];
			for ( module = 1; module <= nModules; ++module ) {
				length = XMLData.modules.module[module-1].keggs.kegg.length();
				ModulesLookupKEGGs[module] = new Array(length+1);
				ModulesLookupKEGGsP[module] = new Array(length);
				for ( i = 0; i < length; ++i ) {
					tempsort.push(new Object());
					item = new XML(XMLData.modules.module[module-1].keggs.kegg[i]);
					tempsort[tempsort.length-1].pvalue = item.pvalue;
					tempsort[tempsort.length-1].module = module;
					tempsort[tempsort.length-1].slot = i+1;
					item.id = keggs.length + 1; 
					keggs.addItem(item);
				}
			}
			ModulesLookupKEGGs[0] = [];
			for ( i = 0; i < keggs.length; ++i ) {
				module = tempsort[i].module;
				ModulesLookupKEGGs[module][tempsort[i].slot] = i+1;
				ModulesLookupKEGGsP[module][i.toString()] = tempsort[i].slot - 1;
				ModulesLookupKEGGs[0].push(module);
			}

			// set modularData[0]
			ModularData[0].nGenes = nGenes;
			ModularData[0].Genes = recode(new XMLListCollection(XMLData.genes.gene));
			ModularData[0].nSamples = nSamples;
			ModularData[0].Samples = recode(new XMLListCollection(XMLData.samples.sample));
			ModularData[0].GO = new XMLListCollection(gos.source);
			ModularData[0].KEGG = new XMLListCollection(keggs.source);

			ModulesLookup = new Vector.<Array>(nGenes * nSamples, true);
			for ( i = 0; i < ModulesLookup.length; ++i ) { ModulesLookup[i] = []; }
			
			ModulesLookupGenes = new Vector.<Array>(nGenes+1, true);
			for ( i = 0; i < ModulesLookupGenes.length; ++i ) { ModulesLookupGenes[i] = []; }

			ModulesLookupSamples = new Vector.<Array>(nSamples+1, true);
			for ( i = 0; i < ModulesLookupSamples.length; ++i ) { ModulesLookupSamples[i] = []; }

			ModulesLookupModules = new Vector.<Array>(nModules+1, true);
			for ( i = 0; i < ModulesLookupModules.length; ++i ) { ModulesLookupModules[i] = []; }

			GenesLookup = new Vector.<Array>(nModules+1, true);
			GenesLookupP = new Vector.<Array>(nModules+1, true);
			SamplesLookup = new Vector.<Array>(nModules+1, true);
			SamplesLookupP = new Vector.<Array>(nModules+1, true);			
			ModularData[0].ModulesRectangles = new Vector.<Array>(nModules+1, true);
			ModularData[0].ModulesOutlines = new Vector.<int>(nModules+1, true);

			setTimeout(treatModules, 10, 1);
			
		}

		public function getModule(module:int): GeneExpressionModule {
			if ( nModules > 0 && module >= 0 && module <= nModules ) {
				if ( ModularData[module].nGenes == 0 ) {
					generateModule(module);
				}
				return ModularData[module];
			}
			return new GeneExpressionModule();
		}
		
		public function generatedModules(): Array {
			var module:int;
			var whichModules:Array = [];
			for ( module = 0; module <= nModules; ++module ) {
				if ( ModularData[module].nGenes != 0 ) {
					whichModules.push(module);
				}
			}
			return whichModules;
		}

		private function generateModule(module:int): void {
			
			var global:GeneExpressionModule = ModularData[0];
			var newmodule:GeneExpressionModule = new GeneExpressionModule();
			
			var genes:Array = GenesLookup[module];
			var samples:Array = SamplesLookup[module];
			var ngenes:int = genes.length;
			var nsamples:int = samples.length;
						
			newmodule.nGenes = ngenes;
			var string:String = Modules.source[module-1].genescores.toString();
		   	var scores:Array = string.split(separator);
			for ( var gene:int = 0; gene < genes.length; ++gene ) {
				var item:XML = new XML(global.Genes[genes[gene]-1]);
				item.id = gene + 1;
				item.score = scores[gene];
				newmodule.Genes.addItem(item);
			}
			newmodule.nSamples = nsamples;
			string = Modules.source[module-1].samplescores.toString();
		   	scores = string.split(separator);
			for ( var sample:int = 0; sample < samples.length; ++sample ) {
				item = new XML(global.Samples[samples[sample]-1]);
				item.id = sample + 1;
				item.score = scores[sample];
				newmodule.Samples.addItem(item);
			}

			newmodule.GO = new XMLListCollection(XMLData.modules.module[module-1].gos.go);
			newmodule.KEGG = new XMLListCollection(XMLData.modules.module[module-1].keggs.kegg);
			
			// get ModulesRectangles
			newmodule.ModulesRectangles = new Vector.<Array>(nModules + 1, true);
			newmodule.ModulesOutlines = new Vector.<int>(nModules + 1, true);
			for ( var m:int = 0; m < ModulesLookupModules[module].length; ++m ) {
				
				var modulep:int = ModulesLookupModules[module][m];
				
				var genesp:Array = GenesLookup[modulep];
				var genespp:Array = [];
				for ( gene = 0; gene < genes.length; ++gene ) {
					genep = genes[gene];
					if ( genesp.indexOf(genep) != -1 ) {
						genespp.push(genep);
					}
				}

				var samplesp:Array = SamplesLookup[modulep];
				var samplespp:Array = [];
				for ( sample = 0; sample < samples.length; ++sample ) {
					samplep = samples[sample];
					if ( samplesp.indexOf(samplep) != -1 ) {
						samplespp.push(samplep);
					}
				}
				
				// determine rectangles
				var rectxleft:Array = []; var rectxright:Array = [];
				var oldgene:int = genes.indexOf(genespp[0]);
				rectxleft.push(oldgene + 1);
				for ( var genepp:int = 0; genepp < genespp.length; ++genepp ) {
					gene = genes.indexOf(genespp[genepp], oldgene);
					if ( gene > oldgene + 1 ) {
						rectxright.push(oldgene + 1);
						rectxleft.push(gene + 1);
					}
					oldgene = gene;
				};
				rectxright.push(oldgene + 1);
	
				var rectytop:Array = []; var rectybottom:Array = [];								
				var oldsample:int = samples.indexOf(samplespp[0]);
				rectytop.push(oldsample + 1);
				for ( var samplepp:int = 0; samplepp < samplespp.length; ++samplepp ) {
					sample = samples.indexOf(samplespp[samplepp], oldsample);
					if ( sample > oldsample + 1 ) {
						rectybottom.push(oldsample + 1);
						rectytop.push(sample + 1);
					}
					oldsample = sample;
				};
				rectybottom.push(oldsample + 1);
				
				newmodule.ModulesRectangles[modulep] = [];
				var maxarea:int = 0;
				var bestrect:int = 0;
				for ( var rectx:int = 0; rectx < rectxright.length; ++rectx ) {
					for ( var recty:int = 0; recty < rectytop.length; ++recty ) {
						var x:int = rectxleft[rectx] - 1;
						var y:int = rectytop[recty] - 1;
						var dx:int = rectxright[rectx] - x;
						var dy:int = rectybottom[recty] - y;
						var area:int = dx * dy;
						if ( area > maxarea ) { 
							maxarea = area;
							bestrect = newmodule.ModulesRectangles[modulep].length;
						}
						newmodule.ModulesRectangles[modulep].push(new Rectangle(x, y, dx, dy));
					}
				}
				newmodule.ModulesOutlines[modulep] = bestrect;

			}

    		var gebitmapdata:LargeBitmapData = new LargeBitmapData(ngenes, nsamples);
    		var modulesbitmapdata:LargeBitmapData = new LargeBitmapData(ngenes, nsamples);
    		gebitmapdata.lock();
    		modulesbitmapdata.lock();
			for ( var genep:int = 0; genep < ngenes; ++genep ) {
				gene = genes[genep];
        		for ( var samplep:int = 0; samplep < nsamples; ++samplep ) {
        			sample = samples[samplep];
					var value:Number = global.GEImage.getPixel(gene-1, sample-1);
					gebitmapdata.setPixel(genep, samplep, value);					
					value = global.ModulesImage.getPixel(gene-1, sample-1);
					var k:int = (gene - 1) * nSamples + sample - 1;
					if ( ModulesLookup[k].length > 0 ) {
						var color:uint = ModulesColors[ModulesLookup[k][ModulesLookup[k].length-1]][0];
						if ( color != ModulesColors[module][0] ) {
							modulesbitmapdata.setPixel(genep, samplep, color);
						}
						if ( color == ModulesColors[module][0] && ModulesLookup[k].length > 1 ) { 
							color = ModulesColors[ModulesLookup[k][ModulesLookup[k].length-2]][0];
							modulesbitmapdata.setPixel(genep, samplep, color);
						}						
					}
				}			
			}			      
			gebitmapdata.unlock();
			modulesbitmapdata.unlock();
			
			newmodule.GEImage = gebitmapdata;
			newmodule.ModulesImage = modulesbitmapdata;
			
			ModularData[module] = newmodule;
		}
		
		public function getInfo(module:int, gene:int, sample:int): Array {
			if ( ModularData[module].nGenes != 0 && gene >= 0 && gene < ModularData[module].nGenes && 
					sample >= 0 && sample < ModularData[module].nSamples ) {
				var geneDescription:XML = ModularData[module].Genes.source[gene];
				var sampleDescription:XML = ModularData[module].Samples.source[sample];
				var genep:int = gene + 1;
				var samplep:int = sample + 1;
				if ( module != 0 ) {
					genep = GenesLookup[module][gene];
					samplep = SamplesLookup[module][sample];
				}
				var k:int = (genep-1) * nSamples + samplep - 1;
				var modules:Array = [];
				if ( k >= 0 && k < ModulesLookup.length ) {
					modules = ModulesLookup[k];
				}
				Data.position = k;
				var data:Number = int(Data.readByte()) / 100.;
				return new Array(geneDescription, sampleDescription, modules, data);
			}
			return null;
		}
		
		
		private function treatModules(modulestart:int):void {
			
			for ( var module:int = modulestart; module <= modulestart + 49; module++ ) {
				
				if ( module == nModules + 1 ) {
					setTimeout(initTreatBitmap, 10);
					return;
				}

	        	var string:String = Modules.source[module-1].containedgenes.toString();
		   		var genes:Array = string.split(separator);
				GenesLookup[module] = [];
				GenesLookupP[module] = [];
				for ( var genep:int = 0; genep < genes.length; ++genep ) {
					var temp:int = int(genes[genep]);
					genes[genep] = temp;
					GenesLookup[module].push(temp);
					GenesLookupP[module][temp.toString()] = genep+1;
					ModulesLookupGenes[temp].push(module);
				}				 
		   		genes.sort(Array.NUMERIC);

				string = Modules.source[module-1].containedsamples.toString();
				var samples:Array = string.split(separator);
				SamplesLookup[module] = [];
				SamplesLookupP[module] = [];
				for ( var samplep:int = 0; samplep < samples.length; ++samplep ) {
					temp = int(samples[samplep]);
					samples[samplep] = temp;
					SamplesLookup[module].push(temp);
					SamplesLookupP[module][temp.toString()] = samplep+1;
					ModulesLookupSamples[temp].push(module);
				}
				samples.sort(Array.NUMERIC);
				
				string = Modules.source[module-1].intersectingmodules.toString();
				var modules:Array = string.split(separator);
				modules.sort(Array.NUMERIC);
				
				// determine rectangles				
				var rectxleft:Array = []; var rectxright:Array = [];
				var oldgene:int = genes[0];
				rectxleft.push(oldgene);
				for ( genep = 0; genep < genes.length; ++genep ) {
					var gene:int = genes[genep];
					if ( gene > oldgene + 1 ) {
						rectxright.push(oldgene);
						rectxleft.push(gene);
					}
					oldgene = gene;
				};
				rectxright.push(oldgene);
	
				var rectytop:Array = []; var rectybottom:Array = [];				
				var oldsample:int = samples[0];
				rectytop.push(oldsample);
				for ( samplep = 0; samplep < samples.length; ++samplep ) {
					var sample:int = samples[samplep];
					if ( sample > oldsample + 1 ) {
						rectybottom.push(oldsample);
						rectytop.push(sample);
					}
					oldsample = sample;
				};
				rectybottom.push(oldsample);
				
				ModularData[0].ModulesRectangles[module] = [];
				var maxarea:int = 0;
				var bestrect:int = 0;
				for ( var rectx:int = 0; rectx < rectxright.length; ++rectx ) {
					for ( var recty:int = 0; recty < rectytop.length; ++recty ) {
						var x:int = rectxleft[rectx] - 1;
						var y:int = rectytop[recty] - 1;
						var dx:int = rectxright[rectx] - x;
						var dy:int = rectybottom[recty] - y;
						var area:int = dx * dy;
						if ( area > maxarea ) { 
							maxarea = area;
							bestrect = ModularData[0].ModulesRectangles[module].length;
						}
						ModularData[0].ModulesRectangles[module].push(new Rectangle(x, y, dx, dy));
					}
				}
				ModularData[0].ModulesOutlines[module] = bestrect;			

				for ( genep = 0; genep < GenesLookup[module].length; ++genep ) {
					gene = GenesLookup[module][genep];
					for ( samplep = 0; samplep < SamplesLookup[module].length; ++samplep ) {
						sample = SamplesLookup[module][samplep];
						var k:int = (gene-1) * nSamples + sample - 1;
						if ( ModulesLookup[k] == null ) {
							ModulesLookup[k] = [module]; 
						} else {
							ModulesLookup[k].push(module);
						}
					}
				}
	
				for ( var modulep:int = 0; modulep < modules.length; ++modulep ) {
					var m:int = int(modules[modulep]);
					if ( m != 0 ) {
						ModulesLookupModules[module].push(m);
					}
				}
								
			}					
			
			dispatchEvent(new UpdateStatusBarEvent("reading module " + module + " of " + nModules + "."));			
			setTimeout(treatModules, 10, module);

		}
		
		private function initTreatBitmap():void {
			
			// set Data and get global Bitmap
			gebitmapdata = new LargeBitmapData(nGenes, nSamples);
			modulesbitmapdata = new LargeBitmapData(nGenes, nSamples);
						
			gebitmapdata.lock();
			modulesbitmapdata.lock();
			Data.position = 0;
		
			setTimeout(treatBitmap, 10, 1);
				
		}

		private function treatBitmap(startgene:int):void {
						
			var gene:int;
			for ( gene = startgene; gene <= startgene + 200; ++gene ) {

				if ( gene == nGenes + 1 ) {
					setTimeout(finishTreatBitmap, 10);
					return;
				}
				
				for ( var sample:int = 1; sample <= nSamples; ++sample ) {
					var value:int = int(Data.readByte());
					var red:uint; var green:uint;
					if ( value >= 0 ) {
						red = value * 2.55;
						green = 0;
					} else {
						red = 0;
						green = -value * 2.55;
					}
					gebitmapdata.setPixel(gene-1, sample-1, (red<<16) + (green<<8) + 0);
					
					var k:int = (gene-1) * nSamples + sample - 1
					//if ( ModulesLookup[k].length > 0 ) {
					//	var color:uint = ModulesColors[ModulesLookup[k][ModulesLookup[k].length-1]][0];
					//	modulesbitmapdata.setPixel(gene-1, sample-1, color);
					//}
					if ( ModulesLookup[k].length > 0 ) {
						var color:uint = ModulesColors[ModulesLookup[k][0]][0];
						for ( var i:int = 1; i < ModulesLookup[k].length; ++i ) {
							color = ( color + ModulesColors[ModulesLookup[k][i]][0] ) / 2
						}
						modulesbitmapdata.setPixel(gene-1, sample-1, color);
					}
				}				
			
			}
			
			dispatchEvent(new UpdateStatusBarEvent("generating bitmap " + int(gene/nGenes*100) + " %."));
			setTimeout(treatBitmap, 10, gene);
		
		}


		private function finishTreatBitmap(): void {	
			gebitmapdata.unlock();
			modulesbitmapdata.unlock();
			ModularData[0].GEImage = gebitmapdata;
			ModularData[0].ModulesImage = modulesbitmapdata;
			dispatchEvent(new GEDCompleteEvent());
		}
			
		
		private function hsv2rgb(hue:Number, sat:Number, val:Number):uint {
		    hue %= 360;
		    if ( val == 0 ) { 
		    	return ( 0 << 16 | 0 << 8 | 0 );
		    }
		    sat /= 100;
		    val /= 100;
		    hue /= 60;
		    var i:Number = Math.floor(hue);
		    var f:Number = hue - i;
		    var p:Number = val*(1-sat);
		    var q:Number = val*(1-(sat*f));
		    var t:Number = val*(1-(sat*(1-f)));
		    var red:Number; var green:Number; var blue:Number;
		    if ( i == 0 ) { red = val; green = t; blue = p; }
		    else if ( i==1 ) { red = q; green = val; blue = p; }
		    else if ( i==2 ) { red = p; green = val; blue = t; }
		    else if ( i==3 ) { red = p; green = q; blue = val; }
		    else if ( i==4 ) { red = t; green = p; blue = val; }
		    else if ( i==5 ) { red = val; green = p; blue = q; }
		    red = Math.floor(red*255);
		    green = Math.floor(green*255);
		    blue = Math.floor(blue*255);
		    return ( red << 16 | green << 8 | blue );
		}	
	}
		
}