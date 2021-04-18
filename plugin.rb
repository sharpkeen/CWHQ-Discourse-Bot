# name: CWHQ-Discourse-Bot
# about: This plugin adds extra functionality to the @system user on a Discourse forum.
# version: 1.5
# authors: Qursch, bronze0202
# url: https://github.com/codewizardshq/CWHQ-Discourse-Bot

require 'date'

courses = Hash.new
courses = {
    36 => "e13_real_prog_00",
    37 => "e14_minecraft_00",
    45 => "e21_prog_concepts_00",
    31 => "e22_wd1_00",
    58 => "e23",
    46 => "e24",
    13 => "intro_prog_py_00",
    14 => "m12_html_css_00",
    15 => "m13_js_00",
    16 => "M14_vr_00",
    17 => "m21_ui_00",
    18 => "m22_database_00",
    47 => "m23_api_00",
    48 => "m24_omg_00",
    53 => "m31_flask_00",
    54 => "m32",
    55 => "m33",
    56 => "m34",
    20 => "h11_intro_python_00",
    21 => "h12_web_dev_00",
    22 => "h13_ui_00",
    23 => "h14_api_00",
    49 => "h21_framework_00",
    50 => "h22_mvc_00",
    51 => "h23",
    52 => "h24",
    59 => "h31",
    60 => "h32",
    61 => "h33",
    62 => "h34",
    11 => false,
    57 => false
}

def get_link(id, username, hash)
    if id == 11 || id == 57 then
        return "`https://scratch.mit.edu/projects/00000000`" 
    else
        if !hash[id].nil? then
            return "`https://" + username + ".codewizardshq.com/" + hash[id] + "/project`"
        end
    end
    return false
end

def create_post(topicId, text)
    post = PostCreator.create(
        Discourse.system_user,
        skip_validations: true,
        topic_id: topicId,
        raw: text)
    unless post.nil?
        post.save(validate: false)
    end
end

def closeTopic(id, message)
    topic = Topic.find_by(id: id)               
    topic.update_status("closed", true, Discourse.system_user, {message: message})
end

def check_title(title)
    if title.downcase.include?("codewizardshq.com") || title.downcase.include?("scratch.mit.edu") then
        return true
    else
        return false
    end
end
def check_all_link_types(text)
    if (text.include?("codewizardshq.com") && !text.include?("/edit")) || (text.include?("cwhq-apps") || text.include?("scratch.mit.edu")) then
        return true
    end
end
after_initialize do
   
    # Missing Link
    DiscourseEvent.on(:topic_created) do |topic|
        
        newTopic = Post.find_by(topic_id: topic.id, post_number: 1)
        topicRaw = newTopic.raw
        lookFor = topic.user.username + ".codewizardshq.com"
        link = get_link(topic.category_id, topic.user.username, courses)
        if link then
            if topicRaw.downcase.include?(lookFor + "/edit") then
                text = "Hello @" + topic.user.username + ", it appears that the link that you provided goes to the editor, and not your project. Please open your project and use the link from that tab. This may look like " + link + "."
                create_post(topic.id, text)
            elsif !topicRaw.downcase.include?(lookFor) && !topicRaw.downcase.include?("cwhq-apps.com") then
                text = "Hello @" + topic.user.username + ", it appears that you did not provide a link to your project. In order to recieve the best help, please edit your topic to contain a link to your project. This may look like " + link + "."
                create_post(topic.id, text)
            end

        end

        topic_title = topic.title
        
        if check_title(topic_title) then
            text = "Hello @" + topic.user.username + ", it appears you provided a link in your topic's title. Please change the title of this topic to something that clearly explains what the topic is about. This will help other forum users know what you want to show or get help with. You can edit your topic title by pressing the pencil icon next to the current one. Be sure to put the link in the main body of your post."
            if topicRaw.downcase.include?(lookFor) || topicRaw.downcase.include?("scratch.mit.edu") then
                create_post(topic.id, text)
            else
                create_post(topic.id, text)
            end
        end
    end

    DiscourseEvent.on(:post_created) do |post|
        
        if post.post_number != 1 && post.user_id != -1 then
        
            raw = post.raw
            oPost = Post.find_by(topic_id: post.topic_id, post_number: 1)
            if post.user.primary_group_id.nil? then 
                return 
            end
            group = Group.find_by(id: post.user.primary_group_id)
            if raw[0, 7].downcase == "@system" then
                if raw[8, 5] == "close" then
                    if (group.name == "Helpers") || (oPost.user.username == post.user.username && !courses[post.topic.category_id].nil?) then
                        text = "Closed by @" + post.user.username + ": " + raw[14..raw.length]
                        if oPost.user.username == post.user.username then
                            text = "Closed by topic creator: " + raw[14..raw.length]
                        end
                        closeTopic(post.topic_id, text)
                    end
                elsif raw[8, 6] == "remove" then
                    if group.name == "Helpers" then
                        first_reply = Post.find_by(topic_id: post.topic_id, post_number: 2)
                        second_reply = Post.find_by(topic_id: post.topic_id, post_number: 3)
                        if !first_reply.nil? && first_reply.user.username == "system" then
                            first_reply.destroy
                        end
                        if !second_reply.nil? && second_reply.user.username == "system" then
                            second_reply.destroy
                        end
                    end
                end
                post.destroy
            end
        end
    end

    DiscourseEvent.on(:post_edited) do |post|
        if post.post_number == 1 && check_all_link_types(post.raw) then
            first_reply = Post.find_by(topic_id: post.topic_id, post_number: 2)
            second_reply = Post.find_by(topic_id: post.topic_id, post_number: 3)
            if !first_reply.nil? && first_reply.user.username == "system" then
                first_reply.destroy
            end
            if !second_reply.nil? && second_reply.user.username == "system" then
                second_reply.destroy
            end
        end
    end
end
