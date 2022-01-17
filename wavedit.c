#ifdef _WIN32
extern int _chsize(int,long);
#define ftruncate _chsize
#else
#include <unistd.h>
#endif

#include <limits.h>
#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define ARRLEN(X) sizeof(X)/sizeof(X[0])
#define MAX(x,y) ((x)>(y)?(x):(y))
#define MIN(x,y) ((x)<(y)?(x):(y))
#define CLAMP(x,a,b) ((x)<(a)?(a):((x)>(b)?(b):(x)))

typedef struct {
	int mriff;	//RIFF
	int size;	//file size minus 8
	int mwave;	//WAVE
	int mfmt;	//"fmt "
	int hdrSz;
	short fmt;		//1 == PCM
	short chans;
	int samprate;
	int byterate;	//== samprate * chans * bitdepth/8
	short bytesPerSamp;	//== chans * bitdepth/8
	short bitdepth;
} wavhdr;

void help(){
puts("wavedit v1.0.1 by SBT - make simple edits to WAV sound files

Usage: wavedit <operation> [<arguments>]

The following operations are supported. All positions are given in seconds.
For all length values, if it is less than 0, it is relative to end of file.
  If it is not given or equal to 0, range spans to end of file.

trim <file> <length>
  Remove all samples past the given length value.

crop <file> <start> [<length>]
  Remove all samples outside the given range.
  If range is outside of the file's bounds, new samples will be zero-filled.

setsample <file> <value>[%]
  Directly set the file's sampling rate.
  The value is in hertz unless given as a percentage (ends with % sign).

resample <file> <value>[%] [<interpolation-method>]
  Perform resampling. See above.
  Interpolation methods: 0-none 1-linear (default)

amp <file> <amount>[%]  [<start> [<length>]]
  Perform amplification. Can be limited to a given region.
  The amount value is in decibels unless followed by a % sign.

rol <file> <seconds> [<start> [<length> [<transition>]]]
ror <file> <seconds> [<start> [<length> [<transition>]]]
  Rotate samples to the left or right by the given amount in seconds.
  Can be limited to a given region.

copy <file> <source-pos> <dest-pos> [<length> [<transition>]]
  Copy samples from one position of the file into another.
  Transition (in seconds) softens the copy bounds to avoid popping.

copyext <file> <source-file> <source-pos> [<dest-pos> [<length> [<transition>]]]
  Same as above, but use another file as source.
  If dest-pos not given, it will equal source-pos.

bitdepth <file> <bits-per-sample>
  Convert file's bit depth to the given value.
");
exit(0);
}

void* kmalloc(int n){
	void *p = malloc(n);
	if(!p) {
		puts("[ERR] Out of memory!");
		exit(-1);
	}
	return p;
}

double readDbl(char* s){
	char* p;
	double val = strtod(s, &p);
	if (*p != 0) {
		printf("[ERR] Bad argument: %s is not a number or out of valid range!\n", s);
		exit(-2);
	}
	return val;
}
int readIntRng(char* s, int min, int max){
	char* p;
	long val = strtol(s, &p, 0);
	if (*p != 0 || val < min || val > max || val < INT_MIN || val > INT_MAX) {
		printf("[ERR] Bad argument: %s is not a number or out of valid range!\n", s);
		exit(-2);
	}
	return (int)val;
}
int readInt(char* s){ readIntRng(s, INT_MIN+1, INT_MAX-1); }


FILE* openFile(char* path, int readonly){
	FILE* fp = fopen(path, readonly ? "rb" : "rb+");
	if (!fp) {
		printf("[ERR] Can't open %s: %s\n", path, strerror(errno));
		exit(-3);
	}
	return fp;
}

int readWav(FILE* fp, wavhdr* hdr, unsigned char** data, int* datalen, int bitop){
	int ret = 0;
	int l, hl = sizeof(wavhdr), dl;
	if (hl != fread(hdr, 1, hl, fp)){
		printf("[ERR] Can't read WAV header: %s\n", strerror(errno));
		exit(-4);
	}
	fseek(fp, 0, SEEK_END);
	l = (int)ftell(fp);
	if (ftell(fp) >= INT_MAX) {
		printf("[ERR] File is too big!\n");
		exit(-6);
	}
	if (hdr->mriff != 0x46464952 || hdr->mwave != 0x45564157 || hdr->mfmt != 0x20746d66) {
		printf("[ERR] File is not a WAV file!\n");
		exit(-6);
	}
	if (hdr->bitdepth != 8 && hdr->bitdepth != 16 && hdr->bitdepth != 32 && (hdr->bitdepth != 24 || !bitop)){
		printf("[ERR] File has unsupported bit depth: %d\n", hdr->bitdepth);
		exit(-6);
	}
	if (hdr->fmt != 1) {
		printf("[WARN] File does not contain PCM data: %d\n", hdr->fmt);
		ret = 1;
	}
	dl = l - 0x1c - hdr->hdrSz;
	dl -= dl % (hdr->chans * (hdr->bitdepth/8));
	*data = kmalloc(dl);
	*datalen = dl;
	fseek(fp, l - dl, SEEK_SET);
	if (dl != fread(*data, 1, dl, fp)) {
		printf("[ERR] Can't read WAV data: %s\n", strerror(errno));
		exit(-4);
	}
	return ret;
}
int writeWav(FILE* fp, wavhdr hdr, unsigned char* data, int datalen) {
	int hl = sizeof(wavhdr), mdata = 0x61746164;
	hdr.mriff = 0x46464952;
	hdr.mwave = 0x45564157;
	hdr.mfmt = 0x20746d66;
	if (!hdr.fmt) hdr.fmt = 1;
	hdr.bytesPerSamp = hdr.chans * (hdr.bitdepth/8);
	hdr.byterate = hdr.bytesPerSamp * hdr.samprate;
	if (!hdr.hdrSz) hdr.hdrSz = hl - 0x14;
	if (data) hdr.size = hdr.hdrSz + 0x14 + datalen;
	fseek(fp, 0, SEEK_SET);
	if (hl != fwrite(&hdr, 1, hl, fp)){
		printf("[ERR] Can't write WAV header: %s\n", strerror(errno));
		exit(-5);
	}
	if (data) {
		fseek(fp, hdr.hdrSz + 0x14, SEEK_SET);
		fwrite(&mdata, 4, 1, fp);
		fwrite(&datalen, 4, 1, fp);
		if (datalen != fwrite(data, 1, datalen, fp)) {
			printf("[ERR] Can't write WAV data: %s\n", strerror(errno));
			exit(-5);
		}
		ftruncate(fileno(fp), hl + datalen + 8);
	}
	return 0;
}
void transition(unsigned char *ndp, unsigned char *odp, unsigned char *odi, unsigned char *odl, int len, int bps){
	signed char *n8, *o8, *t8, *d8;
	signed short *n16, *o16, *t16, *d16;
	signed int *n32, *o32, *t32, *d32;
	double t, inc;
	if (len == 0) return;
	len *= 2;
	if (len < 0) {
		ndp+=len;
		odp+=len;
	}
	d8 = n8 = (signed char*)ndp;
	o8 = (signed char*)odp;
	d16 = n16 = (signed short*)ndp;
	o16 = (signed short*)odp;
	d32 = n32 = (signed int*)ndp;
	o32 = (signed int*)odp;
	if (len < 0) {
		len=-len;
		t8 = n8; n8=o8; o8=t8;
		t16 = n16; n16=o16; o16=t16;
		t32 = n32; n32=o32; o32=t32;
	}
	if (odp - odi < len/4) return;
	if ((odl - odp) - len < len/4) return;
//printf("TR %d (of %d) len %d  odp=%x odi=%x odl=%x\n", odp-odi, odl-odi, len, odp, odi, odl);
	len /= bps;
	for (t = 0, inc = (double)1/len; t < 1 && odp < odl; t += inc, ndp+=bps, odp+=bps)
		if (odp >= odi)
			switch(bps){
			case 1: *d8++  =   (signed char)((float)*o8++ * (1-t) + (float)*n8++ * t + .5f); break;
			case 2: *d16++ = (signed short)((float)*o16++ * (1-t) + (float)*n16++ * t + .5f); break;
			case 4: *d32++ =   (signed int)((float)*o32++ * (1-t) + (float)*n32++ * t + .5f); break;
			}
}



int main(int argc, char** argv){
	const char* ops[] = {"trim","crop","setsamp","resamp","amp","rol","ror","copyex","copy","bitdepth"};
	const char opcs[] = {10,11,20,21,30,40,41,51,50,60};

	int op, ival1, ival2;
	char *file1, *file2 = 0;
	double spos, dpos, len, val1, vtrans=0, t;
	int i, j, l, tb, tc, ts;
	int ssp, sdp, slen, strans;
	FILE *fp, *fpe;
	wavhdr wh, whe;
	unsigned char *wd, *wde, *nd = 0, *od;
	int wdl, wdle, wbps, wbpse, ndl;
	signed char *rwd8, *rnd8;
	signed short *rwd16, *rnd16;
	signed int *rwd32, *rnd32;
	float tf;

	if (argc < 4) help();						//read arguments
	file1 = argv[2];
	for (i=0, l=strlen(argv[1]); i<l; i++)		//op to lowercase
		argv[1][i] |= ' ';
	for (op=0, i=0, l=ARRLEN(ops); i<l; i++)
		if(0 == strncmp(argv[1], ops[i], strlen(ops[i]))){
			op = opcs[i]; break;
		}
	j = 0;
	switch (op){
	default: help();
	case 10:	//trim/crop
	case 11:
		spos = (op == 10 ? 0 : readDbl(argv[3]));
		len = (op == 10 || argc > 4 ? readDbl(argv[op == 10 ? 3 : 4]) : 0);
		break;
	case 21:	//setsample/resample
		ival2 = (argc > 4 ? readIntRng(argv[4], 0, 1) : 1);
	case 20:
		if ((i = strlen(argv[3])) > 0 && argv[3][i-1] == '%'){
			ival1 = -1;
			argv[3][i-1] = '\0';
			val1 = readDbl(argv[3]) / 100;
			if (val1 < 0) val1 = 1 / -val1;
		} else
			ival1 = readIntRng(argv[3], 1, INT_MAX - 1);
		break;
	case 30:	//amp
		if ((i = strlen(argv[3])) > 0 && argv[3][i-1] == '%'){
			j = 1;
			argv[3][i-1] = '\0';
		}
		val1 = readDbl(argv[3]);
		if (j) val1 /= 100;
		else val1 = pow(10, val1/20);
		spos = (argc > 4 ? readDbl(argv[4]) : 0);
		len = (argc > 5 ? readDbl(argv[5]) : 0);
		vtrans = (argc > 6 ? readDbl(argv[6]) : 0);
		break;
	case 40:	//rol/ror
	case 41:
		val1 = readDbl(argv[3]);
		if (val1 < 0) {
			op ^= 1;
			val1 = -val1;
		}
		spos = (argc > 4 ? readDbl(argv[4]) : 0);
		len = (argc > 5 ? readDbl(argv[5]) : 0);
		vtrans = (argc > 6 ? readDbl(argv[6]) : 0);
		break;
	case 51:	//copy/copyext
		file2 = argv[3];
		j = 1;
	case 50:
		if (argc < 5) help();
		spos = readDbl(argv[3+j]);
		dpos = (argc > 4+j ? readDbl(argv[4+j]) : spos);
		len = (argc > 5+j ? readDbl(argv[5+j]) : 0);
		vtrans = (argc > 6+j ? readDbl(argv[6+j]) : 0);
		break;
	case 60:	//convert bitdepth
		ival1 = readIntRng(argv[3], 8, 32);
		if (ival1%8) {
			printf("[ERR] Bad arguments: Bit depth must be a multiple of 8!\n");
			return -2;
		}
		break;
	}

	fp = openFile(file1, 0);					//get ready
	readWav(fp, &wh, &wd, &wdl, op==60?1:0);
	if (file2) {
		fpe = openFile(file2, 1);
		readWav(fpe, &whe, &wde, &wdle, 0);
	}
	wbps = wh.chans * (wh.bitdepth/8);
	wbpse = whe.chans * (whe.bitdepth/8);
	ssp = (int)(spos * wh.samprate) * wbps;
	sdp = (int)(dpos * wh.samprate) * wbps;
	slen = (int)(len * wh.samprate) * wbps;
	strans = (int)((vtrans / 2) * wh.samprate) * wbps;
	if (op == 51){
		ssp = (int)(spos * whe.samprate) * wbpse;
		if (slen < 0) slen = wdl + slen - sdp;
		else if (slen == 0) slen = MIN(wdl - sdp, wdle - ssp);
		if (wh.samprate != whe.samprate) printf("[WARN] Sample rate mismatch: %d vs %d!\n", whe.samprate, wh.samprate);
		if (wh.bitdepth != whe.bitdepth) printf("[WARN] Bit depth mismatch: %d vs %d!\n", whe.bitdepth, wh.bitdepth);
		if (wh.chans != whe.chans) printf("[WARN] Channel count mismatch: %d vs %d!\n", whe.chans, wh.chans);
	} else {
		if (slen < 0) slen = wdl + slen - ssp;
		else if (slen == 0) slen = wdl - ssp;
	}
	if (slen <= 0) {
		printf("[ERR] Bad arguments: Selected region is empty or negative!\n");
		return -2;
	} else if (slen > INT_MAX - 0x40) {
		printf("[ERR] Bad arguments: Selected region is too big!\n");
		return -2;
	}
	switch (op) {
	case 10:
	case 11:
		if (ssp == 0 && slen == wdl) return 1;
		break;
	case 20:
	case 21:
		if (ival1 <= 0) ival1 = (.5f + wh.samprate * val1);
		if (ival1 <= 0) {
			printf("[ERR] Bad arguments: Sample rate cannot be zero or negative!\n");
			return -2;
		}
		val1 = (double)wh.samprate / ival1;
		if (wh.samprate == ival1) return 1;
		break;
	case 30:
		if (val1 == 1) return 1;
		tf = (float)val1;
	case 40:
	case 41:
		if (ssp < 0) ssp = 0;
		if (ssp + slen > wdl) slen = wdl - ssp;
		break;
	case 60:
		if (ival1 == wh.bitdepth) return 1;
		break;
	}
	tc = wh.chans;
	tb = wh.bitdepth/8;
	ts = wh.samprate;
	rwd8 = (signed char*)wd;
	rwd16 = (signed short*)wd;
	rwd32 = (signed int*)wd;

	if (strans < 0) strans = 0;
	if (strans > 0) {
		if (strans > slen) strans = slen;
		od = kmalloc(wdl);
		memcpy(od, wd, wdl);
		ssp -= strans;
		sdp -= strans;
		slen += strans*2;
	}
	switch (op) {								//perform op
	case 10:				//trim/crop
	case 11:
		if (ssp >= 0 && (slen + ssp) <= wdl)
			nd = wd + ssp;
		else {					//if any samples outside original range
			nd = kmalloc(slen);
			memset(nd, 0, slen);
			if ((slen + ssp) >= 0 && ssp < wdl) {
				i = (ssp >= 0 ? ssp : 0);
				j = (ssp >= 0 ? 0 : -ssp);
				memcpy(nd + j, wd + i, MIN(slen - j, wdl - i));
			}
		}
		ndl = slen;
		break;
	case 21:				//resample
		if ((double)wdl * ival1 / wh.samprate >= INT_MAX - 1) {
			printf("[ERR] Resulting output file too big!\n");
			return -7;
		}
		ndl = (int)ceil(((double)(wdl / wbps) / wh.samprate) * ival1) * wbps;
		nd = kmalloc(ndl);
		rnd8 = (signed char*)nd;
		rnd16 = (signed short*)nd;
		rnd32 = (signed int*)nd;
		switch(ival2) {	//interp. method
		case 0:			//none
			for (i = 0, l = ndl / wbps; i < l; i++)
				for (j = 0; j < tc; j++)
					switch(tb){
					case 1: rnd8[i*tc + j]  =  rwd8[(((long long)i * ts) / ival1) * tc + j]; break;
					case 2: rnd16[i*tc + j] = rwd16[(((long long)i * ts) / ival1) * tc + j]; break;
					case 4: rnd32[i*tc + j] = rwd32[(((long long)i * ts) / ival1) * tc + j]; break;
					}
			break;
		case 1:			//linear
			for (t = 0, i = 0, l = ndl/wbps; i < l; i++, t+=val1){
				tf = t - floor(t);
				for (j = 0; j < tc; j++)
					switch(tb){
					case 1: rnd8[i*tc + j]  =  (signed char)((float)rwd8[(int)floor(t) * tc + j] * (1 - tf) + (float)rwd8[(int)ceil(t) * tc + j] * tf); break;
					case 2: rnd16[i*tc + j] = (signed short)((float)rwd16[(int)floor(t) * tc + j] * (1 - tf) + (float)rwd16[(int)ceil(t) * tc + j] * tf); break;
					case 4: rnd32[i*tc + j] =   (signed int)((float)rwd32[(int)floor(t) * tc + j] * (1 - tf) + (float)rwd32[(int)ceil(t) * tc + j] * tf); break;
					}
			}
			break;			
		}
	case 20:				//setsample
		wh.samprate = ival1;
		break;
	case 30:				//amplify
		nd = wd; ndl = wdl;
		rnd8 = (signed char*)nd;
		rnd16 = (signed short*)nd;
		rnd32 = (signed int*)nd;
		for (i = ssp / tb, l = (ssp + slen) / tb; i < l; i++)
			switch(tb){
			case 1: rnd8[i]  = (signed char)CLAMP((float)rwd8[i] * tf + .5f, -0x80, 0x7f); break;
			case 2: rnd16[i] = (signed short)CLAMP((float)rwd16[i] * tf + .5f, -0x8000, 0x7fff); break;
			case 4: rnd32[i] = (signed int)CLAMP((float)rwd32[i] * tf + .5f, -0x80000000, 0x7fffffff); break;
			}
		transition(nd + ssp, od + ssp, od, od+wdl, strans, tb);
		transition(nd + ssp + slen, od + ssp + slen, od, od+wdl, -strans, tb);
		break;
	case 40:				//rol/ror
	case 41:
		sdp = ((int)(val1 * wh.samprate) * wbps) % slen;
		if (sdp <= 0) return 1;
		ndl = wdl;
		nd = kmalloc(ndl);
		if (ssp > 0 || ssp + slen < wdl)
			memcpy(nd, wd, wdl);
		switch(op){
		case 40:
			memcpy(nd + ssp + slen - sdp, wd + ssp, sdp);
			memcpy(nd + ssp, wd + ssp + sdp, slen - sdp);
			break;
		case 41:
			memcpy(nd + ssp, wd + ssp + slen - sdp, sdp);
			memcpy(nd + ssp + sdp, wd + ssp, slen - sdp);
			break;
		}
		transition(nd + ssp, od + ssp, od, od+wdl, strans, tb);
		transition(nd + ssp + slen, od + ssp + slen, od, od+wdl, -strans, tb);
		break;
	case 50:				//copy
		nd = kmalloc(wdl);
		memcpy(nd, wd, wdl);
		wdle = wdl;
		wde = wd;
	case 51:				//copyext
		if (!nd) nd = wd;
		ndl = wdl;
		if (sdp < 0) {
			ssp -= sdp; slen += sdp; sdp = 0;
		}
		if (slen <= 0 || sdp > wdl) {
			printf("[WARN] Copy destination is outside file's bounds!\n");
			return 0;
		}
		if (ssp + strans < 0) memset(nd + sdp, 0, MIN(-ssp, wdl - sdp));
		i = sdp + MAX(0, wdle - ssp);
		l = MIN(slen - MAX(0, wdle - ssp), wdl - i);
		if (ssp + slen - strans > wdle && l > 0) memset(nd + i, 0, l);
		if (ssp < 0) {
			sdp -= ssp; slen += ssp; ssp = 0;
		}
		l = MIN(slen, MIN(wdle - ssp, wdl - sdp));
		if (slen < 0 || ssp > wdle || sdp > wdl)
			printf("[WARN] Copy source is outside file's bounds!\n");
		else
			memcpy(nd + sdp, wde + ssp, l);
		transition(nd + sdp, od + sdp, od, od+wdl, strans, tb);
		transition(nd + sdp + l, od + sdp + l, od, od+wdl, -strans, tb);
		break;
	case 60:				//convert bitdepth
		nd = wd;
		ndl = wdl/tb*(ival1/8);
		if (ndl > wdl)
			nd = kmalloc(ndl);
		wh.bitdepth = ival1;
		ival1/=8;
		if (tb == 1)
			for (i=0; i < wdl; i++)
				wd[i] = wd[i]+0x80;
		for (i=0, j=0; i < slen; i++) {
			if (i%tb==0)
				for (l=0; l < ival1-tb; l++)
					nd[j++] = 0x80;
			if (i%tb >= tb-ival1)
				nd[j++] = wd[i];
		}
		if (ival1 == 1)
			for (i=0; i < ndl; i++)
				nd[i] = nd[i]+0x80;
		break;
	}
	
	writeWav(fp, wh, nd, ndl);
	fclose(fp);
	if (file2) fclose(fpe);

	return 0;
}



