# name: CWHQ-Discourse-Bot
# about: This plugin adds extra functionality to the @system user on a Discourse forum.
# version: 1.0
# author: Qursch
# url: https://github.com/Qursch/CWHQ-Discourse-Bot

require 'date'

courses = [
    {"id" => 4, "short" => "test"},
    {"id" => 36, "short" => "e13"},
    {"id" => 37, "short" => "e14"},
    {"id" => 45, "short" => "e21"},
    {"id" => 31, "short" => "e22"},
    {"id" => 58, "short" => "e23"},
    {"id" => 46, "short" => "e24"},
    {"id" => 13, "short" => "m11"},
    {"id" => 14, "short" => "m12"},
    {"id" => 15, "short" => "m13"},
    {"id" => 16, "short" => "m14"},
    {"id" => 17, "short" => "m21"},
    {"id" => 18, "short" => "m22"},
    {"id" => 36, "short" => "m23"},
    {"id" => 48, "short" => "m24"},
    {"id" => 53, "short" => "m31"},
    {"id" => 54, "short" => "m32"},
    {"id" => 55, "short" => "m33"},
    {"id" => 56, "short" => "m34"},
    {"id" => 20, "short" => "h11"},
    {"id" => 21, "short" => "h12"},
    {"id" => 22, "short" => "h13"},
    {"id" => 23, "short" => "h14"},
    {"id" => 49, "short" => "h21"},
    {"id" => 50, "short" => "h22"},
    {"id" => 51, "short" => "h23"},
    {"id" => 52, "short" => "h24"},
    {"id" => 59, "short" => "h31"},
    {"id" => 60, "short" => "h32"},
    {"id" => 61, "short" => "h33"},
    {"id" => 62, "short" => "h34"},
    {"id" => 11, "short" => "nil"},
    {"id" => 57, "short" => "nil"}
]

def help_category(id, courses)
    courses.each do |i|
        if i["id"] == id then
            return true
        end
    end
    return false
end

after_initialize do

    def get_link(id, username, courses)
        if id == 11 or id == 57 then
            return `https://scratch.mit.edu/projects/00000000`
        else
            courses.each do |i|
                if i["id"] == id then
                    return "`https://" + username + ".codewizardshq.com/" + i["short"] + "/project`"
                end
            end
            return "`https://" + username + ".codewizardshq.com/s00/project` or `https://scratch.mit.edu/projects/00000000`"
        end
    end

    bot = User.find_by(id: -1)
   
    # Missing Link
    DiscourseEvent.on(:topic_created) do |topic|
        
        link = topic.user.username + ".codewizardshq.com"

        if help_category(topic.category_id, courses)
            includesReq = false
            
            newTopic = Post.find_by(topic_id: topic.id)
            topicRaw = newTopic.raw
            
            if topicRaw.downcase.include? link or topicRaw.downcase.include? "scratch.mit.edu" then
                includesReq = true
            end

            if includesReq == false then

                link = get_link(topic.category_id, topic.user.username, courses)
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
            raw = post.raw.downcase.split  
            if raw[0] == "@system" then
                if raw[1] == "close" then
                    if post.user.primary_group_id != nil then
                        group = Group.find_by(id: post.user.primary_group_id)
                        if group.name == "Helpers" then
                            topic = Topic.find_by(id: post.topic_id)
                            topic.update_status("closed", true, bot)
                        end
                    end
                end
            else
                # Bumping Old Topics
                topic = Topic.find_by(id: post.topic_id)
                category = Category.find_by(id: topic.category_id)
                if category.auto_close_hours != nil  && category.auto_close_hours != 0 then
                    lPC = Post.find_by(topic_id: topic.id, post_number: topic.posts_count-1).created_at.to_s
                    last_post_time = DateTime.new(lPC[0,4].to_i, lPC[5,2].to_i, lPC[8,2].to_i).to_time.to_i
                    sC = post.created_at.to_s
                    post_time = DateTime.new(sC[0,4].to_i, sC[5,2].to_i, sC[8,2].to_i).to_time.to_i
                    closetime = category.auto_close_hours * 3600

                    if post_time - last_post_time > closetime then
                        post = PostCreator.create(bot,
                                    skip_validations: true,
                                    topic_id: topic.id,
                                    raw: "Hello @" + post.user.username + ", it appears that this topic should be closed due to it's category's automatic timer. If this is the case, your reply is considered to be bumping this topic, which is against the rules."
                                )
                        unless post.nil?
                            post.save(validate: false)
                        end
                    elsif post_time - last_post_time > closetime - 172800 then
                        post = PostCreator.create(bot,
                                    skip_validations: true,
                                    topic_id: topic.id,
                                    raw: "Hello @" + post.user.username + ", it appears that this topic should be closing in less than 48 hours due to it's category's automatic timer. If this is the case, your reply will keep this topic open for another " + (category.auto_close_hours/24).to_s + " days."
                                )
                        unless post.nil?
                            post.save(validate: false)
                        end
                    end
                end
            end
        end
    end
end
