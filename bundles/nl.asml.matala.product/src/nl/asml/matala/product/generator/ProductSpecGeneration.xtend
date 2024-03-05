package nl.asml.matala.product.generator

import java.util.HashSet


/*class ProductSpecGeneration 
{
	var Product product  
	
	def generateProducSpec(Product prod) 
	{
		product = prod
		var txt = ''''''
		
		txt += 
		'''
		model-name nl.asml.matala
		
		import java.util.List
		import java.net.*
		import java.io.*
		
		product-specification «prod.name» {
		'''
		
		txt +=
		'''
			entity Lot {
				var name : String
				var waferList : List<Wafer>
			}
			
			entity Wafer {
				var name : String
				var layerList : List<Layer>
				var currentLayer : Integer
			}
			
			entity Layer {
				var name : String
			}
			
			entity Data { var value : String }
			
		'''
		txt += generateDataEntities(prod)
		
		for(blk : prod.block) {
			txt += parseBlock(blk)
		}
		
		txt += generateCommunicationBlock(prod)
				
		txt +=
		'''
		}
		'''
		return txt
	}
	
	def generateCommunicationBlock(Product prod) {
		var txt = 
		'''
		«FOR top : prod.topology»
			block «top.name» {
				«FOR b : top.flow»
					var _«b.name.name.toLowerCase» : «b.name.name»
				«ENDFOR»
				
				op execute() {
					«FOR f : top.flow»
						_«f.name.name.toLowerCase» = new «f.name.name»
					«ENDFOR»
					// add custom code
				}
				
				«FOR f : top.flow»
					op getDataInFor«f.name.name»() : void
					{
						«FOR oi : f.outIn»
							_«oi.tbid.bid.name.toLowerCase».«oi.tbid.bin.name» = _«oi.sbid.bid.name.toLowerCase».«oi.sbid.bout.name»
						«ENDFOR»
						«FOR moi : f.moutIn»
							_«moi.tbid.bid.name.toLowerCase».«moi.tbid.bin.name» = _«moi.sbid.bid.name.toLowerCase».«moi.sbid.bout.name»
						«ENDFOR»
					}
				«ENDFOR»
				
				op sendUDP(String ip, int po, String str) : void
				{
					var hostname = ip
					var port = po
						 
					var address = InetAddress.getByName(hostname)
					var socket = new DatagramSocket()
						 
					var byte[] buffer = newArrayList
					buffer = str.getBytes		
						
					var request = new DatagramPacket(buffer, buffer.length, address, po);
					socket.send(request);	
				}
			}
		«ENDFOR»
		'''
		return txt
	}
	
	def generateDataEntities(Product prod) {
		var txt = ''''''
		var dataList = new HashSet<String>
		for(block : prod.block) {
			if(block instanceof Environment) {
				for(i : block.input) dataList.add(i.name)
				for(i : block.output) dataList.add(i.name)
			} else if(block instanceof TwinScan) {
				for(i : block.input) dataList.add(i.name)
				for(i : block.output) dataList.add(i.name)
			} else if(block instanceof YieldStar) {
				for(i : block.input) dataList.add(i.name)
				for(i : block.output) dataList.add(i.name)
			} else if(block instanceof Applications) {
				for(i : block.input) dataList.add(i.name)
				for(i : block.output) dataList.add(i.name)
			} else if(block instanceof Etcher) {
				for(i : block.input) dataList.add(i.name)
				for(i : block.output) dataList.add(i.name)
			} else if(block instanceof Cleaner) {
				for(i : block.input) dataList.add(i.name)
				for(i : block.output) dataList.add(i.name)
			} else {}
		}
		txt += 
		'''
		«FOR input : dataList»
			entity «input.toUpperCase» { var data : Data }
			
		«ENDFOR»
		'''
		return txt
	}
	
	def getBlockInputDataText(OpConnector conn) {
		var txt = ''''''
		for(pre: conn.opPrefix) {
			if(pre instanceof BlockMIn) {
				pre.bid // block id
				pre.bin // mat in
				txt +=
				'''
					=> mat-in: «pre.bin.name»
				'''
			}
			if(pre instanceof BlockIn) {
				pre.bid // block id
				pre.bin // data in
				txt +=
				'''
					-> data-in: «pre.bin.name»
				'''
			}
		}
		return txt
	}
	
	def getBlockOutputDataText(OpConnector conn) {
		var txt = ''''''
		for(post: conn.opPostFix) {
			if(post instanceof BlockMOut) {
				post.bid // block id
				post.bout // mat out
				txt +=
				'''
					<= mat-out: «post.bout.name»
				'''
			}
			if(post instanceof BlockOut) {
				post.bid // block id
				post.bout // data out
				txt +=
				'''
					<- data-out: «post.bout.name»
				'''
			}
		}
		return txt
	}
	
	def generateOperations(Block block) {
		var txt = ''''''
		for(op : block.operation) {
			var opName = op.name
			for(conn : op.io) {
				var cname = conn.name
				txt +=
				'''
				op «opName»_«cname» () : void
				{ 
					print("[Executing] " + "«opName»_«cname»")
					 
					//call the external function with 
					
					//«getBlockInputDataText(conn)»
					
					//and update the following variables
					
					//«getBlockOutputDataText(conn)»
					
					print("[Finished]")
				}
				'''
			}
		}
		return txt
	}
	
	def parseBlock(Block block) {
		var txt = ''''''
		if(block instanceof Environment) {
			txt +=
			'''
			block «block.name» {
				«FOR inp : block.input»
					input «inp.name» : «inp.name.toUpperCase»
				«ENDFOR»
				«FOR inp : block.matIn»
					input «inp.name» : Lot
				«ENDFOR»
				«FOR out : block.output»
					output «out.name» : «out.name.toUpperCase»
				«ENDFOR»
				«FOR inp : block.matOut»
					output «inp.name» : Lot
				«ENDFOR»
				
				op execute() : void
				{
					// call fab equipments here //
				}
				
				«generateOperations(block)»
				
				op print(String str) : void
				{
					System.out.println(str)
				}
			}
			
			'''
		} else if(block instanceof TwinScan) {
			txt +=
			'''
			block «block.name» {
				«FOR inp : block.input»
					input «inp.name» : «inp.name.toUpperCase»
				«ENDFOR»
				«FOR inp : block.matIn»
					input «inp.name» : Lot
				«ENDFOR»
				«FOR out : block.output»
					output «out.name» : «out.name.toUpperCase»
				«ENDFOR»
				«FOR inp : block.matOut»
					output «inp.name» : Lot
				«ENDFOR»
				
				«generateOperations(block)»
				
				op print(String str) : void
				{
					System.out.println(str)
				}
			}
			
			'''
		} else if(block instanceof YieldStar) {
			txt +=
			'''
			block «block.name» {
				«FOR inp : block.input»
					input «inp.name» : «inp.name.toUpperCase»
				«ENDFOR»
				«FOR inp : block.matIn»
					input «inp.name» : Lot
				«ENDFOR»
				«FOR out : block.output»
					output «out.name» : «out.name.toUpperCase»
				«ENDFOR»
				«FOR inp : block.matOut»
					output «inp.name» : Lot
				«ENDFOR»
				
				«generateOperations(block)»

				op print(String str) : void
				{
					System.out.println(str)
				}
			}
			
			'''			
		} else if(block instanceof Applications) {
			txt +=
			'''
			block «block.name» {
				«FOR inp : block.input»
					input «inp.name» : «inp.name.toUpperCase»
				«ENDFOR»
				«FOR inp : block.matIn»
					input «inp.name» : Lot
				«ENDFOR»
				«FOR out : block.output»
					output «out.name» : «out.name.toUpperCase»
				«ENDFOR»
				«FOR inp : block.matOut»
					output «inp.name» : Lot
				«ENDFOR»
				
				«generateOperations(block)»

				op print(String str) : void
				{
					System.out.println(str)
				}
			}
			
			'''			
		} else if(block instanceof Etcher) {
			txt +=
			'''
			block «block.name» {
				«FOR inp : block.input»
					input «inp.name» : «inp.name.toUpperCase»
				«ENDFOR»
				«FOR inp : block.matIn»
					input «inp.name» : Lot
				«ENDFOR»
				«FOR out : block.output»
					output «out.name» : «out.name.toUpperCase»
				«ENDFOR»
				«FOR inp : block.matOut»
					output «inp.name» : Lot
				«ENDFOR»
				
				«generateOperations(block)»
				
				op print(String str) : void
				{
					System.out.println(str)
				}
			}
			
			'''			
		} else if(block instanceof Cleaner) {
			txt +=
			'''
			block «block.name» {
				«FOR inp : block.input»
					input «inp.name» : «inp.name.toUpperCase»
				«ENDFOR»
				«FOR inp : block.matIn»
					input «inp.name» : Lot
				«ENDFOR»
				«FOR out : block.output»
					output «out.name» : «out.name.toUpperCase»
				«ENDFOR»
				«FOR inp : block.matOut»
					output «inp.name» : Lot
				«ENDFOR»
				
				«generateOperations(block)»
				
				op print(String str) : void
				{
					System.out.println(str)
				}
			}
			
			'''			
		} else {}
		return txt
	}
}*/