// Tweeter
// Feed page javascript

// Ajax to retrieve all posts - TODO: needs pagination!
$(function() {
    $.ajax({
        url: '/getAllPosts',
        type: 'GET',
        success: function(res) {
            console.log(res);
            var data = JSON.parse(res);

            var div = $('<div>');
            for (var i = 0; i < data.length; i++) {

              div.append(CreatePost(data[i].Uid, data[i].Text));
              $('.contain').append(div);
            }
        },
        error: function(error) {
            console.log(error);
        }
    });
})

// Function to create the thumbnail html
// See: https://gist.github.com/JamesBream/75e6b9ae85d42a172837
function CreatePost(id, content) {

    var mainDiv = $('<div>').attr('class', 'col-sm-12 col-md-12');

    var panel = $('<div>').attr('class', 'panel panel-defualt');

    var panelBody = $('<div>').attr('class', 'panel-body');

    var media = $('<div>').attr('class', 'media');

    var mediaLeft = $('<div>').attr('class', 'media-left');

    var imglink = $('<a>').attr('href', '../profile/' + id);

    var img = $('<img>').attr({
        'src': '/static/img/profile.png',
        'class': 'media-object',
        'alt': 'profile'
    });

    var mediaBody = $('<div>').attr('class', 'media-body');

    var bodyDiv = $('<div>').text(content);

    var mediaHeading = $('<div>').attr('class', 'media-heading');
    var innerHeading = $('<h4>').text("User ID: " + id);

    mediaBody.append(mediaHeading.append(innerHeading));
    mediaBody.append(bodyDiv);
    mediaLeft.append(imglink.append(img));

    media.append(mediaLeft);
    media.append(mediaBody);
    mainDiv.append(panel.append(panelBody.append(media)));

    return mainDiv;
}
