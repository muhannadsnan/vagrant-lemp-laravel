<?
	$title = "LEMP Stack by Muhannad Senan 2020";
	$email = "Contact: msn-23@live.com";
?>
<html>
<head>
    <title>LEMP - Muhannad Senan</title>
</head>
<body>
    <style>
        body{margin:0}
        .main{font-size: 30pt; padding: 20; text-align: center; background: #38bff4; color: #167da6;}
        p{margin: 30 0; clear: both; text-align: center;}
        .title{background: #167da6; color: #fff; padding: 10 5; border-radius: 10px;}
        .email{font-size: 12pt; margin-bottom: 0;}
        .main a:link{padding:0; background-color: unset;}
        button{border: 5px solid #167da6; padding: 8 30; background-color: #167da6; color: #fff; text-decoration: none; font-size: 20pt; border-radius: 7px; margin-left: 50%; cursor: pointer;}
    </style>

    <div class="main">
        <p class="title"><?=$title?></p>
        <p><img style="float: none;" src="lemp.png"></p>
        <p><a href="next.php"><button>Next >></button> </a></p>
        <p class="email"><?=$email?></p>
    </div>

    <?
        phpinfo();
    ?>
</body>
</html>

