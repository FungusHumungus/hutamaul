
#
#
#
module Hutamaul
	
	class Branch

		attr_accessor :parent	
	  
		def initialize token
			@this_token = token
			@current_branch = nil
			@branches = []
	
			@closed = false
		end
	
		##
		#
		# Pushes new tokens into the branch.
		# Will push the token up any child branches if they havent been closed off.
		def << token
			if current_branch_takes_more
			  @current_branch << token
			elsif token.type == :end_tag
				@closed = true
			elsif token.type == :begin_tag 
				@current_branch = Branch.new token
				add_branch @current_branch
			else
				add_branch token
	 		end
		end

	  def current_branch_takes_more
			!@current_branch.nil? && !@current_branch.closed?
		end
	
	  def closed?
			return @closed
		end
	
		def [] index
			@branches[index]
		end
	
		
		def length
			@branches.length
		end
	
		def char_count
			@branches.inject(0) { |count, branch|
				count + branch.char_count
			}
		end
	
		def take_chars chars, ellipses = '', &options_block
			new_branch = Branch.new @this_token
			@branches.each { |branch|
				taken = branch.take_chars chars, ellipses, &options_block
	    	new_branch.add_branch taken
	
				chars -= taken.char_count
				break if taken.char_count != branch.char_count 
			}
	
			new_branch
		end

		def main_tag
			@this_token
		end

		def to_html
			if @this_token.nil?
					inner_html
			else
					@this_token.to_html + inner_html + @this_token.close_tag
			end
		end
	
		def inner_html
			@branches.inject("") { |total, branch|
					total + branch.to_html
			}
		end
	
		def to_s
			self.to_indented_s(0)
		end
	
		def to_indented_s level
			this_token = @this_token.nil? ? "" : @this_token.to_indented_s(level) 
			
			@branches.inject(this_token) { |total, branch|
					total + branch.to_indented_s(level + 1) 
			}
		end
	
	
		def add_branch branch
			@branches << branch
			branch.parent = self
		end

		##
		#
		# Extracts the nodes that match the given selectors
		#
		def extract selectors
			if is_match(selectors)
				return self
			end

			extracted = []

			@branches
			.select {|branch| branch.respond_to?(:extract) }
			.each do |branch|
					extracted << branch.extract(selectors)
			end

			return extracted.flatten
		end

		def is_match selectors
			return selectors.index { |s| /<#{s}>/ =~	@this_token.to_s }
		end
	end
end	
