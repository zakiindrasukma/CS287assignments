-- Only requirement allowed
require("hdf5")

-- Common functions and classifiers
dofile("nb.lua")
dofile("logisticregression.lua")
dofile("utils.lua")

cmd = torch.CmdLine()

-- Cmd Args
cmd:option('-datafile', '', 'data file')
cmd:option('-classifier', 'nb', 'classifier to use')
cmd:option('-alpha', 1, 'laplacian smoothing factor for NB')
cmd:option('-eta', .5, 'Learning rate')
cmd:option('-lambda', 1, 'regularization penalty')
cmd:option('-minibatch', 500, 'Minibatch size')
cmd:option('-epochs', 50, 'Number of epochs of SGD')


function main() 
   	-- Parse input params
   	opt = cmd:parse(arg)

   	-- Load datafiles
   	printv("Loading datafiles...", 2)
   	local f = hdf5.open(opt.datafile, 'r')
   	local training_input = f:read('train_input'):all():long()
   	local training_output = f:read('train_output'):all():long()
   	local validation_input = f:read('valid_input'):all():long()
   	local validation_output = f:read('valid_output'):all():long()
   	local nfeatures = f:read('nfeatures'):all():long()[1]
   	local nclasses = f:read('nclasses'):all():long()[1]
   	printv("Done.", 2)

   	-- Train.
   	printv("Training classifier...", 2)
   	if opt.classifier == 'nb' then
   		W, b = naiveBayes(training_input, training_output, nfeatures, nclasses, opt.alpha)	
   	elseif (opt.classifier == 'lr') then
   		W, b = logisticRegression(training_input, training_output, validation_input, validation_output, nfeatures, nclasses, opt.minibatch, opt.eta, opt.lambda, opt.epochs)
   	else
   		printv("Not yet implemented.", 0)
   	end
   	printv("Done.", 2)

   -- Test.
   printv("Testing on validation set...", 2)
   local validation_accuracy = validateLinearModel(W:t(), b, validation_input, validation_output)
   printv("Done", 2)
   printv("Accuracy:", 1)
   printv(validation_accuracy, 1)

   return validation_accuracy

end

main()
