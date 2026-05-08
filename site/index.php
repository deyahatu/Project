<?php
$host = getenv('DB_HOST') ?: 'db';
$user = getenv('DB_USER') ?: 'app_user';
$pass = getenv('DB_PASS') ?: '123456';
$name = getenv('DB_NAME') ?: 'recommendations';

$conn = new mysqli($host, $user, $pass, $name);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$resultText = "";
$options = "";

$res = $conn->query("SELECT DISTINCT keyword FROM items ORDER BY keyword");
while ($row = $res->fetch_assoc()) {
    $kw = htmlspecialchars($row['keyword']);
    $options .= "<option value='$kw'>$kw</option>";
}

if ($_SERVER["REQUEST_METHOD"] === "POST") {

    if (!empty($_POST['typed_keyword'])) {
        $keyword = $conn->real_escape_string(trim($_POST['typed_keyword']));
    } else {
        $keyword = $conn->real_escape_string($_POST['selected_keyword']);
    }

    $q = $conn->query(
        "SELECT season FROM items WHERE keyword='$keyword' LIMIT 1"
    );

    if ($q && $q->num_rows > 0) {
        $r = $q->fetch_assoc();
        $resultText = "Recommended season: <b>" .
            htmlspecialchars($r['season']) . "</b>";
    } else {
        $resultText = "No recommendation found for this keyword.";
    }
}

$conn->close();
?>

<!DOCTYPE html>
<html>
<head>
    <title>Smart Recommendation System</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: Arial, sans-serif;
            background: linear-gradient(to right, #89f7fe, #66a6ff);
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .card {
            background: #fff;
            width: 420px;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 15px 30px rgba(0,0,0,0.2);
            text-align: center;
        }

        img {
            width: 100%;
            border-radius: 10px;
            margin-bottom: 15px;
        }

        input, select {
            width: 80%;
            padding: 10px;
            border-radius: 8px;
            font-size: 16px;
            margin-top: 10px;
            border: 1px solid #ccc;
        }

        button {
            margin-top: 15px;
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            background-color: #1e90ff;
            color: #fff;
            font-size: 16px;
            cursor: pointer;
        }

        button:hover {
            background-color: #1565c0;
        }

        .result {
            margin-top: 20px;
            font-size: 18px;
            color: #333;
        }
    </style>
</head>

<body>
<div class="card">
    <img src="https://images.unsplash.com/photo-1504608524841-42fe6f032b4b?auto=format&fit=crop&w=800&q=80">
    <h2>Recommendation System</h2>
    <p>Type or pick a keyword (e.g. <i>hot</i>) and get the matching season.</p>

    <form method="post">
        <input name="typed_keyword" placeholder="Type keyword (optional)">
        <select name="selected_keyword">
            <?= $options ?>
        </select>
        <br>
        <button type="submit">Recommend</button>
    </form>

    <div class="result"><?= $resultText ?></div>
</div>
</body>
</html>
