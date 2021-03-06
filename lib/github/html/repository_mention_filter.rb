module GitHub::HTML
  # Sugar for linking to tickets and commit SHA's in full user/repo references.
  # The following syntaxes are supported where SHA is a 7-40 char hex String and
  # num is a digit.
  #   user@SHA
  #   user/project@SHA
  #   user/project#num
  class RepositoryMentionFilter < Filter
    def perform
      apply_filter(:replace_issue_mentions)
      apply_filter(:replace_commit_mentions)
    end

    def apply_filter(method_name)
      doc.search('text()').each do |node|
        next if node.content =~ /^\s*$/
        next if node.ancestors('pre, code, a').any?
        html = send(method_name, node.content)
        node.replace(html) if html != node.content
      end
    end

    # user/project#num =>
    #   <a href='/user/project/issues/num'>user/project#num</a>
    def replace_issue_mentions(text)
      base_url = self.base_url.chomp('/')
      text.gsub(/(^|\s|[(\[{])([\w-]+\/[.\w-]+)#(\d+)\b/) do |match|
        leader, repo, issue = $1, $2, $3
        url  = [base_url, repo, 'issues', issue].join('/')
        text = "#{repo}##{issue}"
        "#{leader}<a href='#{url}'>#{text}</a>"
      end
    end

    # user/repo@SHA =>
    #   <a href='/user/project/commit/SHA'>user/repo@SHA</a>
    def replace_commit_mentions(text)
      base_url = self.base_url.chomp('/')
      text.gsub(/(^|\s|[({\[])([\w-]+\/[\w.-]+)@([0-9a-f]{7,40})\b/) do |match|
        leader, repo, sha = $1, $2, $3
        url   = [base_url, repo, 'commit', sha].join('/')
        text  = "#{repo}@#{sha[0, 7]}"
        "#{leader}<a href='#{url}'>#{text}</a>"
      end
    end
  end
end
