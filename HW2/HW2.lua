-- Only requirements allowed
require("hdf5")
require("nn")
require("optim")

-- For local use, use these.
dofile('nb.lua')
dofile('logisticregression2.lua')

-- For Odyssey, uncomment these
--dofile('/n/home09/ankitgupta/CS287/CS287assignments/HW2/nb.lua')
--dofile('/n/home09/ankitgupta/CS287/CS287assignments/HW2/logisticregression2.lua')


cmd = torch.CmdLine()

-- Cmd Args
cmd:option('-datafile', '', 'data file')
cmd:option('-testfile', '', 'test file')
cmd:option('-classifier', 'nnfig1', 'classifier to use (nnfig1 or lr or nnpre)')
cmd:option('-alpha', 1, 'laplacian smoothing factor for NB')
cmd:option('-eta', .1, 'Learning rate (.1 for adagrad, 500 for sgd, 10 for nn sgd)')
cmd:option('-lambda', 0, 'regularization penalty (not implemented)')
cmd:option('-minibatch', 2000, 'Minibatch size (500 for nn, 2000 for lr)')
cmd:option('-epochs', 20, 'Number of epochs of SGD')
cmd:option('-optimizer', 'adagrad', 'Name of optimizer to use (adagrad or sgd)')
cmd:option('-hiddenlayers', 10, 'Number of hidden layers (if using neural net)')
cmd:option('-embedding_size', 50, 'Size of word embedding')

function main() 
   -- Parse input params
   opt = cmd:parse(arg)
   printoptions(opt)
   local f = hdf5.open(opt.datafile, 'r')

   local nclasses = f:read('numClasses'):all():long()[1]
   local nsparsefeatures = f:read('numSparseFeatures'):all():long()[1]
   local ndensefeatures = f:read('numDenseFeatures'):all():long()[1]
   local d_win = f:read('d_win'):all():long()[1]

   print("nclasses:", nclasses, "nsparsefeatures:", nsparsefeatures, "ndensefeatures:", ndensefeatures)

   local sparse_training_input = f:read('train_sparse_input'):all():long()
   local dense_training_input = f:read('train_dense_input'):all():double()
   local training_output = f:read('train_output'):all():long()

   local sparse_validation_input = f:read('valid_sparse_input'):all():long()
   local dense_validation_input = f:read('valid_dense_input'):all():double()
   local validation_output = f:read('valid_output'):all():long()
   local word_embeddings = f:read('word_embeddings'):all():double() 

    local sparse_test_input = f:read('test_sparse_input'):all():long()
    local dense_test_input = f:read('test_dense_input'):all():double()


   -- If we are using logistic regression, our features are not words, but word:position pairs. This accounts for that.
   if opt.classifier == "lr" then
	   sparse_training_multiplier = torch.range(1, d_win):resize(1, d_win):expand(sparse_training_input:size(1), d_win):long()
	   sparse_validation_multiplier = torch.range(1, d_win):resize(1, d_win):expand(sparse_validation_input:size(1), d_win):long()
	   sparse_test_multiplier = torch.range(1, d_win):resize(1, d_win):expand(sparse_test_input:size(1), d_win):long()

	   sparse_training_input = torch.cmul(sparse_training_input, sparse_training_multiplier)
	   sparse_validation_input = torch.cmul(sparse_validation_input, sparse_validation_multiplier)
	   sparse_test_input = torch.cmul(sparse_test_input, sparse_test_multiplier)
	   nsparsefeatures = nsparsefeatures * d_win
	end

   print("Imported all data")

   -- Train.
   --W, b = naiveBayes(sparse_training_input, dense_training_input, training_output, nsparsefeatures, nclasses, 1)
   --print(validateLinearModel(W, b, sparse_validation_input, dense_validation_input, validation_output, nsparsefeatures, ndensefeatures))
   local model = LogisticRegression(sparse_training_input, dense_training_input, training_output, 
   	                  sparse_validation_input, dense_validation_input, validation_output, 
   	                  nsparsefeatures, nclasses, opt.minibatch, opt.eta, opt.epochs, opt.lambda, opt.classifier, opt.hiddenlayers, opt.optimizer, word_embeddings, opt.embedding_size, d_win)
   print("Options and accuracy")
   printoptions(opt)
   print(getaccuracy(model, sparse_validation_input, dense_validation_input, validation_output))

   -- Test.
   print("Writing to test file")
   if (opt.testfile ~= '') then
      local scores = torch.squeeze(model:forward({sparse_test_input, dense_test_input}))
      local _, class_preds = torch.max(scores, 2)
      local results = class_preds:squeeze()
      file = io.open(opt.testfile, 'w')
      io.output(file)
      io.write("ID,Class")
      for test_i = 1, results:size()[1] do
         io.write(test_i, ',', results[test_i], '\n')
      end
   end
end

main()
