<?php
$version = "glogana.php 050823";

#	ezpdf -> http://www.ros.co.nz/pdf
#$ezpdf_path = "../ezpdf/";
if ((@$ezpdf_path)) {
	if (file_exists($ezpdf_path))
		include_once($ezpdf_path."class.ezpdf.php");
	else
		unset($ezpdf_path);
}

if (is_uploaded_file($fn = @$_FILES["fl"]["tmp_name"]) !== TRUE) {
	print <<<EOO
<HTML><HEAD><TITLE>$version</TITLE></HEAD><BODY>

<H1>$version</H1>

<FORM enctype="multipart/form-data" method=POST>
<P>file(gps*.log) : <INPUT type=file name=fl>
<BR>range :
<LABEL><INPUT type=radio name=range value=100 checked>100m</LABEL>
<LABEL><INPUT type=radio name=range value=300>300m</LABEL>
<LABEL><INPUT type=radio name=range value=500>500m</LABEL>
<LABEL><INPUT type=radio name=range value=1000>1000m</LABEL>
<BR>output type :
<LABEL><INPUT type=radio name=outputtype value=0 checked>PNG</LABEL>
<LABEL><INPUT type=radio name=outputtype value=1>PDF</LABEL>
---- <INPUT type=submit></P>
</FORM>

<HR>
</BODY></HTML>
EOO;
	die();
}


class	event {
	var	$parent;
	var	$sat = -1;
	var	$n = 0;
	var	$e = 0;
	var	$h = 0;
	var	$date = "";
	function	event(&$parent, $line) {
		$this->parent =& $parent;
		$bytes = 23;
		if (count($list = explode(" ", $line)) < $bytes)
			return;
		for ($i=0; $i<count($list); $i++)
			$list[$i] = ("0x".$list[$i]) + 0;
		
		if ($list[0] != 0xe0)
			return;
		$this->sat = 0;
		if ($list[$bytes - 1] != 0xea)
			return;
		$sum = 0;
		for ($i=0; $i<$bytes-1; $i++)
			$sum ^= $list[$i];
		if ($sum != 0)
			return;
		$this->sat = $list[20];
		$val = ($list[3] << 21)|($list[4] << 14)|($list[5] << 7)| $list[6];
		if (($list[3] & 0x40))
			$val -= 0x10000000;
		$this->n = $val / 600000.0;	# 1d = 60.0000m
		$val = ($list[7] << 21)|($list[8] << 14)|($list[9] << 7)| $list[10];
		if (($list[7] & 0x40))
			$val -= 0x10000000;
		$this->e = $val / 600000.0;	# 1d = 60.0000m
		$val = ($list[11] << 21)|($list[12] << 14)|($list[13] << 7)| $list[14];
		if (($list[11] & 0x40))
			$val -= 0x10000000;
		$this->h = $val / 10.0;		# 1m = 10
		
		$pos = $bytes;
		$bytes = 10;
		if (count($list) < $pos + $bytes)
			return;
		if ($list[$pos] != 0xe1)
			return;
		if ($list[$pos + $bytes - 1] != 0xea)
			return;
		$sum = 0;
		for ($i=0; $i<$bytes-1; $i++)
			$sum ^= $list[$pos + $i];
		if ($sum != 0)
			return;
		$this->date = sprintf("20%02d/%02d/%02d %02d:%02d:%02d GMT", $list[$pos + 2], $list[$pos + 3], $list[$pos + 4], $list[$pos + 5], $list[$pos + 6], $list[$pos + 7]);
	}
	function	isvalid() {
		return ($this->sat >= 0);
	}
	function	ispositionfixed() {
		return ($this->sat >= 4);
	}
	function	n() {
		return $this->n;
	}
	function	e() {
		return $this->e;
	}
	function	h() {
		return $this->h;
	}
	function	sat() {
		return $this->sat;
	}
	function	x() {
		return $this->parent->e2x($this->e);
	}
	function	y() {
		return $this->parent->n2y($this->n);
	}
	function	length(&$event) {
		$sum = pow($this->x() - $event->x(), 2);
		$sum += pow($this->y() - $event->y(), 2);
		$sum += pow($this->h() - $event->h(), 2);
		return sqrt($sum);
	}
	function	date() {
		return $this->date;
	}
}


class	area {
	var	$area = null;
	function	update($e, $n) {
		if ($this->area === null) {
			$this->area = array(0, 0, 0, 0);
			$this->area[0] = $this->area[2] = $this->area[4] = $e;
			$this->area[1] = $this->area[3] = $this->area[5] = $n;
			return;
		}
		$this->area[0] = min($this->area[0], $e);
		$this->area[1] = max($this->area[1], $n);
		$this->area[2] = max($this->area[2], $e);
		$this->area[3] = min($this->area[3], $n);
		$this->area[4] = ($this->area[0] + $this->area[2]) / 2;	# center
		$this->area[5] = ($this->area[1] + $this->area[3]) / 2;
	}
	function	e2x($e) {
		$mul = 40000000.0 / 360;	# 360d = 40000km
		return ($e - $this->area[4]) * $mul * cos(deg2rad($this->area[5]));
	}
	function	n2y($n) {
		$mul = 40000000.0 / 360;	# 360d = 40000km
		return ($n - $this->area[5]) * $mul;
	}
}


class	eventlist {
	var	$list;
	var	$area;
	var	$lastdate = "";
	function	eventlist() {
		$this->list = (array)null;
		$this->area =& new area();
	}
	function	e2x($e) {
		return $this->area->e2x($e);
	}
	function	n2y($n) {
		return $this->area->n2y($n);
	}
	function	readline($fp) {
		while (($line = fgets($fp)) !== FALSE) {
			$event =& new event($this, trim($line));
			if ($event->isvalid() !== TRUE)
				continue;
			if ($this->lastdate > $event->date())
				continue;
			$this->list[] =& $event;
			if ($event->ispositionfixed() !== TRUE)
				continue;
			$this->lastdate = $event->date();
			$this->area->update($event->e(), $event->n());
		}
	}
	function	drawgraph(&$genv, $range, $sx, $sy, $width, $height, $color) {
		$genv->setlinewidth(1);
		if (($count = count($this->list)) <= 0)
			return;
		$genv->setgeometry($count / 2, 6, $sx, $sy, ($width + 0.0) / $count, -$height / 12.0);
		if (($c = $color[3]) >= 0) {
			$genv->setcolor($c);
			$genv->addpoint($count, 0);
			$genv->addpoint(0, 0);
			for ($i=0; $i<$count; $i++)
				$genv->addpoint($i, $this->list[$i]->sat());
			$genv->fillpolygon();
		}
		$unit_time = 60;
		$genv->setcolor(0x000000);
		for ($i=0; $i<$count; $i+=$unit_time) {
			$genv->addpoint($i, 0);
			$genv->addpoint($i, 12);
			$genv->drawline();
			$genv->setcolor(0xc0c0c0);
		}
		$genv->setgeometry($count / 2, 0, $sx, $sy, ($width + 0.0) / $count, -($height + 0.0) / $range / 2);
		$unit_length = 100;
		$genv->setcolor(0x000000);
		for ($i=0; $i<$range; $i+=$unit_length) {
			$genv->addpoint(0, $i);
			$genv->addpoint($count, $i);
			$genv->drawline();
			$genv->addpoint(0, -$i);
			$genv->addpoint($count, -$i);
			$genv->drawline();
			$genv->setcolor(0xc0c0c0);
		}
		$genv->setlinewidth(2);
		if (($c = $color[0]) >= 0) {
			$genv->setcolor($c);
			for ($i=0; $i<$count; $i++)
				if ($this->list[$i]->ispositionfixed())
					$genv->addpoint($i, $this->list[$i]->x());
				else
					$genv->drawline();
			$genv->drawline();
		}
		if (($c = $color[1]) >= 0) {
			$genv->setcolor($c);
			for ($i=0; $i<$count; $i++)
				if ($this->list[$i]->ispositionfixed())
					$genv->addpoint($i, $this->list[$i]->y());
				else
					$genv->drawline();
			$genv->drawline();
		}
		if (($c = $color[2]) >= 0) {
			$genv->setcolor($c);
			for ($i=0; $i<$count; $i++)
				if ($this->list[$i]->ispositionfixed())
					$genv->addpoint($i, $this->list[$i]->h());
				else
					$genv->drawline();
			$genv->drawline();
		}
		$genv->setcolor(0x000000);
		$genv->drawtext($count * 3 / 4, -$range * 3 / 4, $this->lastdate);
	}
	function	drawmap(&$genv, $range, $sx, $sy, $width, $height, $color, $labelcolor = array(-1, -1)) {
		$genv->setlinewidth(1);
		if (($count = count($this->list)) <= 0)
			return;
		$genv->setgeometry(0, 0, $sx, $sy, ($width + 0.0) / $range / 2, -($height + 0.0) / $range / 2);
		$unit_length = 100;
		$genv->setcolor(0x000000);
		for ($i=0; $i<$range; $i+=$unit_length) {
			$genv->addpoint3d(-$range, $i, 0);
			$genv->addpoint3d($range, $i, 0);
			$genv->drawline();
			$genv->addpoint3d(-$range, -$i, 0);
			$genv->addpoint3d($range, -$i, 0);
			$genv->drawline();
			$genv->addpoint3d($i, -$range, 0);
			$genv->addpoint3d($i, $range, 0);
			$genv->drawline();
			$genv->addpoint3d(-$i, -$range, 0);
			$genv->addpoint3d(-$i, $range, 0);
			$genv->drawline();
			$genv->setcolor(0xc0c0c0);
		}
		if (($c = $labelcolor[0]) >= 0) {
			$genv->setcolor($c);
			$genv->drawtext3d($range, 0, 0, "E");
		}
		if (($c = $labelcolor[1]) >= 0) {
			$genv->setcolor($c);
			$genv->drawtext3d(0, $range, 0, "N");
		}
		$null = null;
		if (($c = $color[2]) >= 0) {
			$genv->setcolor($c);
			$target =& $null;
			for ($i=0; $i<$count; $i++) {
				if ($this->list[$i]->ispositionfixed() !== TRUE) {
					$target =& $null;
					continue;
				}
				if ($target === null)
					;
				else if ($target->length($this->list[$i]) < 10)
					continue;
				$target =& $this->list[$i];
				$genv->addpoint3d($target->x(), $target->y(), 0);
				$genv->addpoint3d($target->x(), $target->y(), $target->h());
				$genv->drawline();
			}
		}
		$genv->setlinewidth(2);
		if (($c = $color[1]) >= 0) {
			$genv->setcolor($c);
			for ($i=0; $i<$count; $i++)
				if ($this->list[$i]->ispositionfixed())
					$genv->addpoint3d($this->list[$i]->x(), $this->list[$i]->y(), 0);
				else
					$genv->drawline();
			$genv->drawline();
		}
		if (($c = $color[0]) >= 0) {
			$genv->setcolor($c);
			for ($i=0; $i<$count; $i++)
				if ($this->list[$i]->ispositionfixed())
					$genv->addpoint3d($this->list[$i]->x(), $this->list[$i]->y(), $this->list[$i]->h());
				else
					$genv->drawline();
			$genv->drawline();
		}
	}
}


class	genv {
	var	$ux = 0;
	var	$uy = 0;
	var	$sx = 0;
	var	$sy = 0;
	var	$zx = 1.0;
	var	$zy = 1.0;
	function	genv() {
		return;
	}
	function	setgeometry($ux, $uy, $sx, $sy, $zx = 1.0, $zy = 1.0) {
		$this->ux = $ux;
		$this->uy = $uy;
		$this->sx = $sx;
		$this->sy = $sy;
		$this->zx = $zx;
		$this->zy = $zy;
	}
	function	setlinewidth($width) {
		die("setlinewidth called.");
	}
	function	setcolor($color) {
		die("setcolor called.");
	}
	function	addpoint($x, $y) {
		die("addpoint called.");
	}
	function	addpoint3d($x, $y, $z) {
		$this->addpoint($x + $y / 2, $y / 2 + $z);
	}
	function	drawline($color) {
		die("drawline called.");
	}
	function	fillpolygon($color) {
		die("fillpolygon called");
	}
	function	drawtext($x, $y, $text) {
		die("drawtext called.");
	}
	function	drawtext3d($x, $y, $z, $text) {
		$this->drawtext($x + $y / 2, $y / 2 + $z, $text);
	}
}


class	genv_png extends genv {
	var	$gid;
	var	$pointlist;
	var	$color;
	function	genv_png($width = 1000, $height = 1400) {
		parent::genv();
		$this->pointlist = (array)null;
		
		$this->gid = imagecreate($width, $height) or die("imagecreate failed.");
		$this->color = imagecolorresolve($this->gid, 255, 255, 255);
		imagefilledrectangle($this->gid, 0, 0, $width - 1, $height - 1, $this->color);
	}
	function	close() {
		header("Content-Type: image/png");
		imagepng($this->gid);
		imagedestroy($this->gid);
		die();
	}
	function	setlinewidth($width) {
		imagesetthickness($this->gid, $width);
	}
	function	setcolor($color) {
		$this->color = imagecolorresolve($this->gid, ($color >> 16) & 0xff, ($color >> 8) & 0xff, $color & 0xff);
	}
	function	addpoint($x, $y) {
		$this->pointlist[] = ($x - $this->ux) * $this->zx + $this->sx;
		$this->pointlist[] = ($y - $this->uy) * $this->zy + $this->sy;
	}
	function	drawline() {
		if (count($this->pointlist) < 4) {
			$this->pointlist = (array)null;
			return;
		}
		for ($i=0; $i<count($this->pointlist)-2; $i+=2)
			imageline($this->gid, $this->pointlist[$i], $this->pointlist[$i + 1], $this->pointlist[$i + 2], $this->pointlist[$i + 3], $this->color);
		$this->pointlist = (array)null;
	}
	function	fillpolygon() {
		if (count($this->pointlist) < 6) {
			$this->pointlist = (array)null;
			return;
		}
		imagefilledpolygon($this->gid, $this->pointlist, count($this->pointlist) / 2, $this->color);
		$this->pointlist = (array)null;
	}
	function	drawtext($x, $y, $text) {
		$x = ($x - $this->ux) * $this->zx + $this->sx;
		$y = ($y - $this->uy) * $this->zy + $this->sy;
		imagestring($this->gid, 4, $x, $y, $text, $this->color);
	}
}


class	genv_pdf extends genv {
	var	$pdf;
	var	$pointcount = 0;
	var	$pos_y;
	var	$zoom;
	var	$margin;
	function	genv_pdf($width = 1000, $height = 1400) {
		$paper_width = $this->mm2pnt(210);
		$paper_height = $this->mm2pnt(297);
		$this->margin = $this->mm2pnt(15);
		$this->zoom = ($paper_width - $this->margin * 2) / $width;
		$this->pos_y = $paper_height - $this->margin;
		
		$this->pdf = pdf_new() or die("pdf_new failed.");
		pdf_open_file($this->pdf);
		pdf_begin_page($this->pdf, $paper_width, $paper_height);
	}
	function	mm2pnt($val) {
		return $val * 72 / 25.4;
	}
	function	setgeometry($ux, $uy, $sx, $sy, $zx = 1.0, $zy = 1.0) {
		$this->ux = $ux;
		$this->uy = $uy;
		$this->sx = $sx * $this->zoom + $this->margin;
		$this->sy = -$sy * $this->zoom + $this->pos_y;
		$this->zx = $zx * $this->zoom;
		$this->zy = -$zy * $this->zoom;
	}
	function	close() {
		pdf_end_page($this->pdf);
		pdf_close($this->pdf);
		
		$content = pdf_get_buffer($this->pdf);
		pdf_delete($this->pdf);
		
		header("Content-Type: application/pdf");
		header("Content-Length: ".strlen($content));
		header("Content-Disposition: inline; filename=glogana.pdf");
		print $content;
		die();
	}
	function	setlinewidth($width) {
		pdf_setlinewidth($this->pdf, $width * $this->zoom);
	}
	function	setcolor($color) {
		$r = (($color >> 16) & 0xff) / 255.0;
		$g = (($color >> 8) & 0xff) / 255.0;
		$b = ($color & 0xff) / 255.0;
		pdf_setcolor($this->pdf, "both", "rgb", $r, $g, $b, FALSE);
	}
	function	addpoint($x, $y) {
		$x = ($x - $this->ux) * $this->zx + $this->sx;
		$y = ($y - $this->uy) * $this->zy + $this->sy;
		if ($this->pointcount++ == 0)
			pdf_moveto($this->pdf, $x, $y);
		else
			pdf_lineto($this->pdf, $x, $y);
	}
	function	drawline() {
		if ($this->pointcount == 0)
			return;
		if ($this->pointcount < 2)
			pdf_endpath($this->pdf);
		else
			pdf_stroke($this->pdf);
		$this->pointcount = 0;
	}
	function	fillpolygon() {
		if ($this->pointcount == 0)
			return;
		if ($this->pointcount < 2)
			pdf_endpath($this->pdf);
		else {
			pdf_closepath($this->pdf);
			pdf_fill($this->pdf);
		}
		$this->pointcount = 0;
	}
	function	drawtext($x, $y, $text) {
		$fontsize = 15 * $this->zoom;
		$x = ($x - $this->ux) * $this->zx + $this->sx;
		$y = ($y - $this->uy) * $this->zy + $this->sy;
#		$font = pdf_findfont($this->pdf, "Times-Roman", "host", 0) or die("pdf_findfont failed.");
		$font = pdf_findfont($this->pdf, "Helvetica-Bold", "host", 0) or die("pdf_findfont failed.");
		pdf_setfont($this->pdf, $font, $fontsize);
		pdf_set_text_pos($this->pdf, $x, $y - $fontsize);
		pdf_show($this->pdf, $text);
	}
}


class	genv_ezpdf extends genv {
	var	$pdf;
	var	$pointlist;
	var	$pos_y;
	var	$zoom;
	var	$margin;
	function	genv_ezpdf($width = 1000, $height = 1400) {
		$paper_width = $this->mm2pnt(210);
		$paper_height = $this->mm2pnt(297);
		$this->margin = $this->mm2pnt(15);
		$this->zoom = ($paper_width - $this->margin * 2) / $width;
		$this->pos_y = $paper_height - $this->margin;
		
		$this->pdf =& new Cezpdf();
	}
	function	mm2pnt($val) {
		return $val * 72 / 25.4;
	}
	function	setgeometry($ux, $uy, $sx, $sy, $zx = 1.0, $zy = 1.0) {
		$this->ux = $ux;
		$this->uy = $uy;
		$this->sx = $sx * $this->zoom + $this->margin;
		$this->sy = -$sy * $this->zoom + $this->pos_y;
		$this->zx = $zx * $this->zoom;
		$this->zy = -$zy * $this->zoom;
	}
	function	close() {
		$this->pdf->ezStream();
		die();
	}
	function	setlinewidth($width) {
		$this->pdf->setLineStyle($width * $this->zoom);
	}
	function	setcolor($color) {
		$r = (($color >> 16) & 0xff) / 255.0;
		$g = (($color >> 8) & 0xff) / 255.0;
		$b = ($color & 0xff) / 255.0;
		$this->pdf->setColor($r, $g, $b);
		$this->pdf->setStrokeColor($r, $g, $b);
	}
	function	addpoint($x, $y) {
		$this->pointlist[] = ($x - $this->ux) * $this->zx + $this->sx;
		$this->pointlist[] = ($y - $this->uy) * $this->zy + $this->sy;
	}
	function	drawline() {
		if (count($this->pointlist) < 4) {
			$this->pointlist = (array)null;
			return;
		}
		$this->pdf->polygon($this->pointlist, count($this->pointlist) / 2, 0);
		$this->pointlist = (array)null;
	}
	function	fillpolygon() {
		if (count($this->pointlist) < 6) {
			$this->pointlist = (array)null;
			return;
		}
		$this->pdf->polygon($this->pointlist, count($this->pointlist) / 2, 1);
		$this->pointlist = (array)null;
	}
	function	drawtext($x, $y, $text) {
		global	$ezpdf_path;
		
		$this->pdf->selectFont($ezpdf_path."fonts/Helvetica-Bold.afm");
		$fontsize = 15 * $this->zoom;
		$x = ($x - $this->ux) * $this->zx + $this->sx;
		$y = ($y - $this->uy) * $this->zy + $this->sy;
		$this->pdf->addText($x, $y - $fontsize, $fontsize, $text);
	}
}


$eventlist =& new eventlist();

$fp = fopen($fn, "r") or die("fopen failed.");
$eventlist->readline($fp);
fclose($fp);

switch (@$_POST["outputtype"] + 0) {
	default:
	case	0:
		$genv =& new genv_png();
		break;
	case	1:
		if ((@$ezpdf_path))
			$genv =& new genv_ezpdf();
		else
			$genv =& new genv_pdf();
		break;
}

if (@$_POST["range"] + 0 <= 150)
	$range = 150;
else if (@$_POST["range"] + 0 <= 350)
	$range = 350;
else if (@$_POST["range"] + 0 <= 550)
	$range = 550;
else
	$range = 1080;
#$color = array(0xff0000, 0x00ff00, 0x0000ff, 0xffff80);
$color = array(0x0000ff, 0x00ff00, 0xff0000, 0xffff80);
$eventlist->drawgraph($genv, $range, 500, 1200, 1000, 400, $color);
$eventlist->drawmap($genv, $range, 500, 700, 800, 800, array($color[2], 0x000000, 0x000000), $color);
#$eventlist->drawmap($genv, $range, 500, 700, 800, 800, array(0xff0000, 0x000000, 0x000000), $color);
$genv->close();
?>
