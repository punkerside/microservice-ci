var express = require('express');
var app = express();
var bodyParser = require('body-parser');
var mongoose = require('mongoose');
var router = express.Router();

var db = mongoose.connect('mongodb://mongo/lol-shop');

var Product = require('./model/product.js');
var WishList = require('./model/wishList.js');

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({
    extended: false
}));

// middleware to use for requests
router.use(function(request, response, next) {
    // logging
    console.log("Something is happeing...");
    next(); // make sure we go to next routes.
});

router.get('/', function(request, response) {
    response.send("Welcome to League Of Legend Shop api!");
});

router.route('/products')
    // create a product (accessed at POST http://localhost:3000/api/products)
    .post(function(request, response) {
        var product = new Product();
        product.title = request.body.title;
        product.price = request.body.price;
        product.save(function(err, savedProduct) {
            if (err) {
                response.status(500).send('Could not save product.');
            } else {
                response.send(savedProduct);
            }
        });
    })
    // get all the products (accessed at GET http://localhost:3000/api/products)
    .get(function(request, response) {
        Product.find({}, function(err, resultProducts) {
            if (err) {
                response.status(500).send('Could not find product.');
            } else {
                response.send(resultProducts);
            }
        });
    });

router.route('/products/:product_id')
    // get the product with that id (accessed at GET http://localhost:3000/api/products/:product_id)
    .get(function(request, response) {
        Product.findById(request.params.product_id, function(err, resultProduct) {
            if (err) {
                response.status(500).send('Could not find product.');
            } else {
                response.send(resultProduct);
            }
        });
    })
    // update the product with this id (accessed at PUT http://localhost:3000/api/products/:product_id)
    .put(function(request, response) {
        Product.findById(request.params.product_id, function(err, resultProduct) {
            if (err) {
                response.status(500).send('Could not find the product.');
            } else {
                resultProduct.title = request.body.title;
                resultProduct.price = request.body.price;
                resultProduct.save(function(err) {
                    if (err) {
                        response.status(500).send('Could not save the product.');
                    } else {
                        Product.find({}, function(err, resultProducts) {
                            if (err) {
                                response.status(500).send('Could not find products.');
                            } else {
                                response.send(resultProducts);
                            }
                        });
                    }
                });
            }
        });
    })
    // delete the product with this id (accessed at DELETE http://localhost:3000/api/products/:product_id)
    .delete(function(request, response) {
        Product.remove({
            _id: request.params.product_id
        }, function(err, resultProduct) {
            if (err) {
                response.status(500).send('Could not delete the product.');
            } else {
                response.send('success');
            }
        });
    });

router.route('/wishlists')
    .get(function(request, response) {
        WishList.find({}, function(err, resultWishLists) {
            if (err) {
                response.status(500).send({
                    error: 'Could not get wishlists'
                });
            } else {
                response.send(resultWishLists);
            }
        });
    })
    .post(function(request, response) {
        var newWishList = new WishList();
        newWishList.title = request.body.title;
        newWishList.save(function(err, savedWishList) {
            if (err) {
                response.status(500).send({
                    error: 'Could not add item to wishlist'
                });
            } else {
                response.send(savedWishList);
            }
        });
    });

router.route('/wishlists/:wishlist_id')
    .get(function(request, response) {
        WishList.findById(
            request.params.wishlist_id,
            function(err, resultWishLists) {
                if (err) {
                    response.status(500).send({
                        error: 'Could not get the wishlist'
                    });
                } else {
                    response.send(resultWishLists);
                }
            });
    }).put(function(request, response) {
        WishList.findById(
            request.params.wishlist_id,
            function(err, resultWishLists) {
                if (err) {
                    response.status(500).send({
                        error: 'Could not get the wishlist'
                    });
                } else {
                    resultWishLists.title = request.body.title;
                    resultWishLists.save(function(err) {
                        if (err) {
                            response.status(500).send({
                                error: 'Found your wish list but could not save the wishlist'
                            });
                        } else {
                            response.send(resultWishLists);
                        }
                    });
                }
            });
    }).delete(function(request, response) {
        WishList.remove({
            _id: request.params.wishlist_id
        }, function(err, resultWishLists) {
            if (err) {
                response.status(500).send('Could not delete the wishlist.');
            } else {
                response.send('success');
            }
        });
    });

router.route('/wishlists/:wishlist_id/products')
    .delete(function(request, response) {
        WishList.findOne({
            _id: request.params.wishlist_id
        }, function(err, targetWishList) {
            if (err) {
                response.status(500).send('Could not find the wishlist.');
            } else {
                // A = []; // This is perfect if you don't have references to the original array.
                // A.splice(0,A.length); or A.length = 0; // similar in performence.
                targetWishList.products.splice(0, targetWishList.products.length);
                targetWishList.save(function(err) {
                    if (err) {
                        response.status(500).send('Could not save the wishlist.');
                    } else {
                        WishList.findOne({
                            _id: targetWishList._id
                        }, function(err, resultWishList) {
                            if (err) {
                                response.status(500).send('Could not find the wishlist.');
                            } else {
                                response.send(resultWishList);
                            }
                        });
                    }
                });
            }
        });
    });

router.route('/wishlists/:wishlist_id/products/:product_id')
    .put(function(request, response) {
        WishList.findOne({
            _id: request.params.wishlist_id
        }, function(err, targetWishList) {
            if (err) {
                response.status(500).send('Could not find the wishlist.');
            } else {
                Product.findOne({
                    _id: request.params.product_id
                }, function(err, targetProduct) {
                    if (err) {
                        response.status(500).send('Found your wishlist but Could not find the product.');
                    } else {
                        // $addToSet do not add the item to the given field if it already contains it,
                        // $push will add the given object to field whether it exists or not.
                        WishList.update({
                            _id: targetWishList._id
                        }, {
                            $addToSet: {
                                products: targetProduct._id
                            }
                        }, function(err) {
                            if (err) {
                                response.status(500).send('Could not update the WishList.');
                            } else {
                                WishList.findOne({
                                    _id: targetWishList._id
                                }, function(err, resultWishlist) {
                                    if (err) {
                                        response.status(500).send('Could not find the wishList.');
                                    } else {
                                        response.send(resultWishlist);
                                    }
                                });
                            }
                        });
                    }
                });
            }
        });
    })
    .delete(function(request, response) {
        WishList.findOne({
            _id: request.params.wishlist_id
        }, function(err, resultWishlist) {
            if (err) {
                response.status(500).send('Could not find the wishList.');
            } else {
                var checkIndex = resultWishlist.products.indexOf(request.params.product_id);
                if (checkIndex > -1) {
                    resultWishlist.products.splice(checkIndex, 1);
                    resultWishlist.save(function(err) {
                        if (err) {
                            response.status(500).send('Could not save the wishList.');
                        } else {
                            response.send(resultWishlist);
                        }
                    });
                } else {
                    response.send('Your product is not in your wish list');
                }
            }
        });
    });

// all of our routes will be prefixed with /api
app.use('/api', router);

app.listen(3000, '0.0.0.0', function() {
    console.log('LOL shop api is running on port 3000')
});
