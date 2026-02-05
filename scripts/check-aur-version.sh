# 支持命令行参数，如果没有则使用环境变量
PKG_NAME="${1:-$PKG_NAME}"

# 获取 AUR 包的最新版本信息
AUR_INFO=$(curl -s "https://aur.archlinux.org/rpc/?v=5&type=info&arg=${PKG_NAME}")
LATEST_VERSION=$(echo $AUR_INFO | jq -r '.results[0].Version')
PACKAGE_BASE=$(echo $AUR_INFO | jq -r '.results[0].PackageBase')

# 检查是否是 -git 包
if [[ "$PKG_NAME" == *-git ]]; then
  echo "Detected -git package: ${PKG_NAME}"
  
  # 从 AUR 获取 PKGBUILD 信息，提取上游仓库 URL
  PKGBUILD_URL="https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${PACKAGE_BASE}"
  PKGBUILD_CONTENT=$(curl -s "$PKGBUILD_URL")
  
  # 首先提取 url= 变量
  URL_VAR=$(echo "$PKGBUILD_CONTENT" | grep -E "^url=" | sed -n 's/.*=["'\'']\?\([^"'\'']*\)["'\'']\?/\1/p' | head -1)
  
  # 尝试多种方式提取源仓库 URL（支持多行 source）
  SOURCE_REPO=$(echo "$PKGBUILD_CONTENT" | awk '/^source(_[^=]*)?=\(/, /^\)/' | grep -E "git\+" | sed -n 's/.*git+\([^"#)'\'']*\).*/\1/p' | head -1)
  
  # 如果提取的 URL 包含变量引用（如 $url 或 ${url}），尝试替换
  if [[ "$SOURCE_REPO" == *'$url'* || "$SOURCE_REPO" == *'${url}'* ]] && [[ -n "$URL_VAR" ]]; then
    SOURCE_REPO=$(echo "$SOURCE_REPO" | sed "s|\${url}|$URL_VAR|g" | sed "s|\$url|$URL_VAR|g")
  fi
  
  # 如果 SOURCE_REPO 为空，直接使用 url 变量
  if [[ -z "$SOURCE_REPO" ]] && [[ -n "$URL_VAR" ]]; then
    SOURCE_REPO="$URL_VAR"
  fi
  
  # 确保 URL 以 .git 结尾（如果需要的话）
  if [[ -n "$SOURCE_REPO" ]] && [[ "$SOURCE_REPO" != *.git ]] && [[ "$SOURCE_REPO" == *github.com* || "$SOURCE_REPO" == *gitlab.com* ]]; then
    SOURCE_REPO="${SOURCE_REPO}.git"
  fi
  
  if [[ -n "$SOURCE_REPO" ]] && [[ "$SOURCE_REPO" != *'$'* ]] && [[ "$SOURCE_REPO" != *'{'* ]]; then
    echo "Upstream repository: ${SOURCE_REPO}"
    
    # 获取上游仓库的最新 commit hash
    # 支持 GitHub, GitLab, 和通用 Git 仓库
    if [[ "$SOURCE_REPO" == *github.com* ]]; then
      # GitHub API
      REPO_PATH=$(echo "$SOURCE_REPO" | sed 's|.*github.com/||' | sed 's|\.git||')
      LATEST_COMMIT=$(curl -s "https://api.github.com/repos/${REPO_PATH}/commits/HEAD" | jq -r '.sha // empty' | cut -c1-8)
    elif [[ "$SOURCE_REPO" == *gitlab.com* ]]; then
      # GitLab API
      REPO_PATH=$(echo "$SOURCE_REPO" | sed 's|.*gitlab.com/||' | sed 's|\.git||' | sed 's|/|%2F|g')
      LATEST_COMMIT=$(curl -s "https://gitlab.com/api/v4/projects/${REPO_PATH}/repository/commits/HEAD" | jq -r '.short_id // empty')
    else
      # 通用 Git 仓库 (使用 git ls-remote)
      LATEST_COMMIT=$(git ls-remote "$SOURCE_REPO" HEAD 2>/dev/null | awk '{print substr($1,1,8)}')
    fi
    
    if [[ -n "$LATEST_COMMIT" ]]; then
      echo "Latest upstream commit: ${LATEST_COMMIT}"
      # 使用 commit hash 作为版本号，这样只有在上游有新提交时才会触发构建
      LATEST_VERSION="${LATEST_COMMIT}"
    else
      echo "Warning: Could not fetch upstream commit, using AUR version"
    fi
  else
    echo "Warning: Could not extract source repository from PKGBUILD (found: ${SOURCE_REPO})"
  fi
fi

# 尝试修复GitHub Actions无法正确处理冒号带来的问题
LATEST_VERSION=$(echo "$LATEST_VERSION" | sed 's/:/*/g')

echo "latest_version=${LATEST_VERSION}" >> $GITHUB_OUTPUT
echo "package_base=${PACKAGE_BASE}" >> $GITHUB_OUTPUT
echo "Latest version: ${LATEST_VERSION}"