# name: CWHQ-Discourse-Bot
# about: This plugin adds extra functionality to the @system user on a Discourse forum.
# version: 1.0
# author: Qursch
# url: https://github.com/Qursch/CWHQ-Discourse-Bot

require 'date'

courses = [
    {"id" => 4, "short" => "test"},
    {"id" => 36, "short" => "e13_real_prog_00"},
    {"id" => 37, "short" => "e14_minecraft_00"},
    {"id" => 45, "short" => "e21_prog_concepts_00"},
    {"id" => 31, "short" => "e22_wd1_00"},
    {"id" => 58, "short" => "e23"},
    {"id" => 46, "short" => "e24"},
    {"id" => 13, "short" => "intro_prog_py_00"},
    {"id" => 14, "short" => "m12_html_css_00"},
    {"id" => 15, "short" => "m13_js_00"},
    {"id" => 16, "short" => "M14_vr_00"},
    {"id" => 17, "short" => "m21_ui_00"},
    {"id" => 18, "short" => "m22_database_00"},
    {"id" => 36, "short" => "m23_api_00"},
    {"id" => 48, "short" => "m24_omg_00"},
    {"id" => 53, "short" => "m31_flask_00"},
    {"id" => 54, "short" => "m32"},
    {"id" => 55, "short" => "m33"},
    {"id" => 56, "short" => "m34"},
    {"id" => 20, "short" => "h11_intro_python_00"},
    {"id" => 21, "short" => "h12_web_dev_00"},
    {"id" => 22, "short" => "h13_ui_00"},
    {"id" => 23, "short" => "h14_api_00"},
    {"id" => 49, "short" => "h21_framework_00"},
    {"id" => 50, "short" => "h22_mvc_00"},
    {"id" => 51, "short" => "h23"},
    {"id" => 52, "short" => "h24"},
    {"id" => 59, "short" => "h31"},
    {"id" => 60, "short" => "h32"},
    {"id" => 61, "short" => "h33"},
    {"id" => 62, "short" => "h34"},
    {"id" => 11, "short" => nil, "full" => "`https://scratch.mit.edu/projects/00000000`"},
    {"id" => 57, "short" => nil, "full" => "`https://scratch.mit.edu/projects/00000000`"}
]

after_initialize do

    def get_link(id, username, courses)
        courses.each do |i|
            if i["id"] == id then
                if !i["short"].nil? then
                    return "`https://" + username + ".codewizardshq.com/" + i["short"] + "/project`"
                else
                    return i["full"]    
                end
            end
        end
        return false
    end

    bot = User.find_by(id: -1)
   
    # Missing Link
    DiscourseEvent.on(:topic_created) do |topic|
        
        link = get_link(topic.category_id, topic.user.username, courses)
        if link then
            includesReq = false
            
            newTopic = Post.find_by(topic_id: topic.id)
            topicRaw = newTopic.raw
            lookFor = topic.user.username + ".codewizardshq.com"

            if topicRaw.downcase.include? lookFor or topicRaw.downcase.include? "scratch.mit.edu" then
                includesReq = true
            end

            if includesReq == false then

                text = "Hello @" + topic.user.username + ", it appears that you did not provide a link to your project. In order to recieve the best help, please edit your topic to contain a link to your project. This may look like " + link + "."
                post = PostCreator.create(bot,
                            skip_validations: true,
                            topic_id: topic.id,
                            raw: text 
                        )
                unless post.nil?
                    post.save(validate: false)
                end
            end
        end
    end

    
    DiscourseEvent.on(:post_created) do |post|
        
        if post.post_number != 1 && post.user_id != -1 then

            # Close Topic Command        
            raw = post.raw.downcase
            if raw[0, 13] == "@system close" then
                if post.user.primary_group_id != nil then
                    group = Group.find_by(id: post.user.primary_group_id)
                    if group.name == "Helpers" then
                        topic = Topic.find_by(id: post.topic_id)
                        topic.update_status("closed", true, bot)
                    end
                end
            end
        end
    end
end
