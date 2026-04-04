<?php
if(!file_exists("data")) mkdir("data", 0777, true);
if(!file_exists("uploads")) mkdir("uploads", 0777, true);
if(!file_exists("data/posts.json")) file_put_contents("data/posts.json", json_encode([]));

function readJson($file){
    return json_decode(file_get_contents($file), true);
}

function writeJson($file, $data){
    file_put_contents($file, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
}

$posts = readJson("data/posts.json");

if($_SERVER['REQUEST_METHOD'] === 'POST'){
    if(isset($_POST['action']) && $_POST['action'] === 'write'){
        $newPost = [
            "id" => time(),
            "title" => $_POST['title'],
            "content" => $_POST['content'],
            "comments" => [],
            "image" => "",
            "views" => 0
        ];
        if(isset($_FILES['image']) && $_FILES['image']['tmp_name']){
            $ext = pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION);
            $filename = "uploads/".time()."_".rand(1000,9999).".".$ext;
            move_uploaded_file($_FILES['image']['tmp_name'], $filename);
            $newPost['image'] = $filename;
        }
        $posts[] = $newPost;
        writeJson("data/posts.json", $posts);
        header("Location: index.php");
        exit;
    } elseif(isset($_POST['action']) && $_POST['action'] === 'comment'){
        $id = $_POST['id'];
        $comment = $_POST['comment'];
        foreach($posts as &$post){
            if($post['id'] == $id){
                $post['comments'][] = $comment;
            }
        }
        writeJson("data/posts.json", $posts);
        header("Location: index.php?id=".$id);
        exit;
    }
}

if(isset($_GET['id'])){
    $id = $_GET['id'];
    foreach($posts as &$post){
        if($post['id'] == $id){
            $post['views'] += 1;
            writeJson("data/posts.json", $posts);
            $current = $post;
            break;
        }
    }
}

usort($posts, function($a,$b){
    return $b['views'] - $a['views'];
});
?>

<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ì´ê³µë·ì»´ ì»¤ë®¤ëí°</title>
<style>
body { font-family: Arial, sans-serif; max-width:800px; margin:auto; padding:10px; background:#f9f9f9; }
h1 { text-align:center; }
form { margin-top:10px; }
input, textarea, button { width:100%; padding:8px; margin:5px 0; box-sizing:border-box; }
textarea { height:80px; }
button { background:#007bff; color:white; border:none; cursor:pointer; }
button:hover { background:#0056b3; }
.post { background:white; padding:15px; margin-bottom:15px; border-radius:5px; box-shadow:0 0 5px rgba(0,0,0,0.1); }
.post img { max-width:100%; height:auto; margin-top:10px; border-radius:5px; }
.comment { margin-left:10px; font-size:14px; color:#555; padding:2px 0; }
.comment-form { display:flex; gap:5px; margin-top:5px; }
.comment-form input { flex:1; }
.popular { color:#ff5722; font-weight:bold; }
</style>
</head>
<body>

<h1>ì´ê³µë·ì»´ ì»¤ë®¤ëí°</h1>

<?php if(isset($current)): ?>
<div class="post">
    <h2><?=htmlspecialchars($current['title'])?></h2>
    <p><?=nl2br(htmlspecialchars($current['content']))?></p>
    <?php if($current['image']): ?>
        <img src="<?=htmlspecialchars($current['image'])?>">
    <?php endif; ?>
    <p>ì¡°íì: <?=$current['views']?> | ëê¸: <?=count($current['comments'])?></p>

    <div>
        <strong>ëê¸</strong>
        <?php foreach($current['comments'] as $c): ?>
            <div class="comment">- <?=htmlspecialchars($c)?></div>
        <?php endforeach; ?>
        <form method="post" class="comment-form">
            <input type="hidden" name="action" value="comment">
            <input type="hidden" name="id" value="<?=$current['id']?>">
            <input type="text" name="comment" placeholder="ëê¸ ìì±" required>
            <button type="submit">ëê¸</button>
        </form>
    </div>
    <a href="index.php">ëª©ë¡ì¼ë¡ ëìê°ê¸°</a>
</div>
<?php else: ?>

<h2>ê¸ì°ê¸°</h2>
<form method="post" enctype="multipart/form-data">
    <input type="hidden" name="action" value="write">
    ì ëª©: <input type="text" name="title" required>
    ë´ì©: <textarea name="content" required></textarea>
    ì´ë¯¸ì§: <input type="file" name="image"><br>
    <button type="submit">ìì±</button>
</form>

<hr>

<h2>ê²ìê¸ ëª©ë¡ (ì¡°íì ê¸°ì¤ ì¸ê¸°ê¸)</h2>

<?php foreach($posts as $post): ?>
<div class="post">
    <h3>
        <a href="index.php?id=<?=$post['id']?>"><?=htmlspecialchars($post['title'])?></a>
        <?php if($post['views'] >= 3) echo '<span class="popular">ð¥ ì¸ê¸°ê¸</span>'; ?>
    </h3>
    <p><?=nl2br(htmlspecialchars($post['content']))?></p>
    <?php if($post['image']): ?>
        <img src="<?=htmlspecialchars($post['image'])?>">
    <?php endif; ?>
    <p>ì¡°íì: <?=$post['views']?> | ëê¸: <?=count($post['comments'])?></p>
</div>
<?php endforeach; ?>

<?php endif; ?>

</body>
</html>
