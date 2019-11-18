var mongoose = require('mongoose');
var Schema = mongoose.Schema;

var product = new Schema({
    title: String,
    price: Number,
    likes: {
        type: Number,
        defalut: 0
    }
});

module.exports = mongoose.model('Product', product);
