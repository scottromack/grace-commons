# Every old address still answers (unit `library: the files match the tree`, Scott 2026-11-23): each page
# the move put in a folder gets a redirect from the address it had, read from _data/moves.json, the one
# record of the move, so no page carries the list itself. jekyll-redirect-from writes the redirects; this
# generator runs first and hands it each page's old addresses.
module GraceMoved
  class Generator < Jekyll::Generator
    priority :highest

    def generate(site)
      moves = site.data["moves"] or return
      back = {}
      moves.fetch("files", {}).each { |old, now| (back[now] ||= []) << old }
      moves.fetch("deleted", {}).each { |old, now| (back[now] ||= []) << old }
      site.pages.each do |page|
        path = page.relative_path.sub(%r{\A/}, "")
        olds = (back[path] || []).dup
        moves.fetch("dirs", {}).each do |before, after|
          olds << before + path[after.length..] if path.start_with?(after)
        end
        next if olds.empty?
        from = Array(page.data["redirect_from"])
        olds.each { |old| from << address(old) }
        page.data["redirect_from"] = from.uniq
      end
    end

    # the address Jekyll gave a page at `old`: index.md and README.md answer as their folder
    def address(old)
      return "/" + old.sub(%r{(index|README)\.md\z}, "") if old =~ %r{(\A|/)(index|README)\.md\z}
      "/" + old.sub(/\.(md|idd)\z/, ".html")
    end
  end
end
