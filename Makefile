CC = g++ -std=gnu++98
CFLAGS = -Wall -c -I.
COFLAGS = -Wall -O3 -ffast-math -c -I.
LFLAGS = -Wall -O3 -I.

SAMTOOLS = samtools-1.3
HTSLIB = htslib-1.3
SAMHEADERS = $(SAMTOOLS)/$(HTSLIB)/htslib/sam.h
SAMFLAGS = -I$(SAMTOOLS)/$(HTSLIB)
SAMLIBS = $(SAMTOOLS)/$(HTSLIB)/libhts.a
BOOST = boost # overriderable, defaulting to local copy

PROGRAMS = rsem-extract-reference-transcripts rsem-synthesis-reference-transcripts rsem-preref rsem-parse-alignments rsem-build-read-index rsem-run-em rsem-tbam2gbam rsem-run-gibbs rsem-calculate-credibility-intervals rsem-simulate-reads rsem-bam2wig rsem-get-unique rsem-bam2readdepth rsem-sam-validator rsem-scan-for-paired-end-reads


.PHONY : all ebseq clean

all : $(PROGRAMS)

$(SAMTOOLS)/$(HTSLIB)/libhts.a : 
	cd $(SAMTOOLS) ; ${MAKE} all

Transcript.h : utils.h

Transcripts.h : utils.h my_assert.h Transcript.h

rsem-extract-reference-transcripts : utils.h my_assert.h GTFItem.h Transcript.h Transcripts.h extractRef.cpp
	$(CC) $(LFLAGS) $(LDFLAGS) $(CPPFLAGS) $(CXXFLAGS) extractRef.cpp -o rsem-extract-reference-transcripts

rsem-synthesis-reference-transcripts : utils.h my_assert.h Transcript.h Transcripts.h synthesisRef.cpp
	$(CC) $(LFLAGS) $(LDFLAGS) $(CPPFLAGS) $(CXXFLAGS) synthesisRef.cpp -o rsem-synthesis-reference-transcripts

BowtieRefSeqPolicy.h : RefSeqPolicy.h

RefSeq.h : utils.h

Refs.h : utils.h RefSeq.h RefSeqPolicy.h PolyARules.h


rsem-preref : preRef.o
	$(CC) $(CPPFLAGS) $(LDFLAGS) preRef.o -o rsem-preref

preRef.o : utils.h RefSeq.h Refs.h PolyARules.h RefSeqPolicy.h AlignerRefSeqPolicy.h preRef.cpp
	$(CC) $(CPPFLAGS) $(CXXFLAGS) $(COFLAGS) preRef.cpp


SingleRead.h : Read.h

SingleReadQ.h : Read.h

PairedEndRead.h : Read.h SingleRead.h

PairedEndReadQ.h : Read.h SingleReadQ.h


PairedEndHit.h : SingleHit.h

HitContainer.h : GroupInfo.h

sam_utils.h : $(SAMHEADERS) Transcript.h Transcripts.h

SamParser.h : $(SAMHEADERS) sam_utils.h utils.h my_assert.h SingleRead.h SingleReadQ.h PairedEndRead.h PairedEndReadQ.h SingleHit.h PairedEndHit.h Transcripts.h


rsem-parse-alignments : parseIt.o $(SAMLIBS)
	$(CC) $(LDFLAGS) -o rsem-parse-alignments parseIt.o $(SAMLIBS) -lz -lpthread

parseIt.o : $(SAMHEADERS) sam_utils.h utils.h my_assert.h GroupInfo.h Transcripts.h Read.h SingleRead.h SingleReadQ.h PairedEndRead.h PairedEndReadQ.h SingleHit.h PairedEndHit.h HitContainer.h SamParser.h parseIt.cpp
	$(CC) $(CPPFLAGS) $(CXXFLAGS) -Wall -O2 -c -I. $(SAMFLAGS) parseIt.cpp


rsem-build-read-index : utils.h buildReadIndex.cpp
	$(CC) $(LFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(LDFLAGS) buildReadIndex.cpp -o rsem-build-read-index

simul.h : $(BOOST)/random.hpp

ReadReader.h : SingleRead.h SingleReadQ.h PairedEndRead.h PairedEndReadQ.h ReadIndex.h

SingleModel.h : utils.h my_assert.h Orientation.h LenDist.h RSPD.h Profile.h NoiseProfile.h ModelParams.h RefSeq.h Refs.h SingleRead.h SingleHit.h ReadReader.h simul.h

SingleQModel.h : utils.h my_assert.h Orientation.h LenDist.h RSPD.h QualDist.h QProfile.h NoiseQProfile.h ModelParams.h RefSeq.h Refs.h SingleReadQ.h SingleHit.h ReadReader.h simul.h

PairedEndModel.h : utils.h my_assert.h Orientation.h LenDist.h RSPD.h Profile.h NoiseProfile.h ModelParams.h RefSeq.h Refs.h SingleRead.h PairedEndRead.h PairedEndHit.h ReadReader.h simul.h 

PairedEndQModel.h : utils.h my_assert.h Orientation.h LenDist.h RSPD.h QualDist.h QProfile.h NoiseQProfile.h ModelParams.h RefSeq.h Refs.h SingleReadQ.h PairedEndReadQ.h PairedEndHit.h ReadReader.h simul.h

HitWrapper.h : HitContainer.h



BamWriter.h : $(SAMHEADERS) sam_utils.h utils.h my_assert.h SingleHit.h PairedEndHit.h HitWrapper.h Transcript.h Transcripts.h

sampling.h : $(BOOST)/random.hpp

WriteResults.h : utils.h my_assert.h GroupInfo.h Transcript.h Transcripts.h RefSeq.h Refs.h Model.h SingleModel.h SingleQModel.h PairedEndModel.h PairedEndQModel.h

rsem-run-em : EM.o $(SAMLIBS)
	$(CC) $(LDFLAGS) -o rsem-run-em EM.o $(SAMLIBS) -lz -lpthread

EM.o : $(SAMHEADERS) utils.h my_assert.h Read.h SingleRead.h SingleReadQ.h PairedEndRead.h PairedEndReadQ.h SingleHit.h PairedEndHit.h Model.h SingleModel.h SingleQModel.h PairedEndModel.h PairedEndQModel.h Refs.h GroupInfo.h HitContainer.h ReadIndex.h ReadReader.h Orientation.h LenDist.h RSPD.h QualDist.h QProfile.h NoiseQProfile.h ModelParams.h RefSeq.h RefSeqPolicy.h PolyARules.h Profile.h NoiseProfile.h Transcript.h Transcripts.h HitWrapper.h BamWriter.h simul.h sam_utils.h sampling.h $(BOOST)/random.hpp WriteResults.h EM.cpp
	$(CC) $(CPPFLAGS) $(COFLAGS) $(SAMFLAGS) $(CXXFLAGS) EM.cpp

bc_aux.h : $(SAMHEADERS)

BamConverter.h : $(SAMHEADERS) sam_utils.h utils.h my_assert.h bc_aux.h Transcript.h Transcripts.h

rsem-tbam2gbam : $(SAMHEADERS) utils.h Transcripts.h Transcript.h BamConverter.h sam_utils.h my_assert.h bc_aux.h tbam2gbam.cpp $(SAMLIBS)
	$(CC) $(LFLAGS) $(SAMFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(LDFLAGS) tbam2gbam.cpp $(SAMLIBS) -lz -lpthread -o $@

wiggle.o: $(SAMHEADERS) sam_utils.h utils.h my_assert.h wiggle.h wiggle.cpp
	$(CC) $(CPPFLAGS) $(COFLAGS) $(CXXFLAGS) $(SAMFLAGS) wiggle.cpp

rsem-bam2wig : utils.h my_assert.h wiggle.h wiggle.o $(SAMLIBS) bam2wig.cpp
	$(CC) $(CPPFLAGS) $(CXXFLAGS) $(LDFLAGS) $(LFLAGS) bam2wig.cpp wiggle.o $(SAMLIBS) -lz -lpthread -o $@

rsem-bam2readdepth : utils.h my_assert.h wiggle.h wiggle.o $(SAMLIBS) bam2readdepth.cpp
	$(CC) $(CPPFLAGS) $(CXXFLAGS) $(LDFLAGS) $(LFLAGS) bam2readdepth.cpp wiggle.o $(SAMLIBS) -lz -lpthread -o $@


rsem-simulate-reads : simulation.o
	$(CC) $(CPPFLAGS) $(LDFLAGS) -o rsem-simulate-reads simulation.o

simulation.o : utils.h Read.h SingleRead.h SingleReadQ.h PairedEndRead.h PairedEndReadQ.h Model.h SingleModel.h SingleQModel.h PairedEndModel.h PairedEndQModel.h Refs.h RefSeq.h GroupInfo.h Transcript.h Transcripts.h Orientation.h LenDist.h RSPD.h QualDist.h QProfile.h NoiseQProfile.h Profile.h NoiseProfile.h simul.h $(BOOST)/random.hpp WriteResults.h simulation.cpp
	$(CC) $(CPPFLAGS) $(COFLAGS) $(CXXFLAGS) simulation.cpp

rsem-run-gibbs : Gibbs.o
	$(CC) $(CPPFLAGS) $(CXXFLAGS) -o rsem-run-gibbs Gibbs.o -lpthread

#some header files are omitted
Gibbs.o : utils.h my_assert.h $(BOOST)/random.hpp sampling.h Model.h SingleModel.h SingleQModel.h PairedEndModel.h PairedEndQModel.h RefSeq.h RefSeqPolicy.h PolyARules.h Refs.h GroupInfo.h WriteResults.h Gibbs.cpp
	$(CC) $(CPPFLAGS) $(COFLAGS) $(CXXFLAGS) Gibbs.cpp

Buffer.h : my_assert.h

rsem-calculate-credibility-intervals : calcCI.o
	$(CC) $(CPPFLAGS) $(LDFLAGS) -o rsem-calculate-credibility-intervals calcCI.o -lpthread

#some header files are omitted
calcCI.o : utils.h my_assert.h $(BOOST)/random.hpp sampling.h Model.h SingleModel.h SingleQModel.h PairedEndModel.h PairedEndQModel.h RefSeq.h RefSeqPolicy.h PolyARules.h Refs.h GroupInfo.h WriteResults.h Buffer.h calcCI.cpp
	$(CC) $(CPPFLAGS) $(COFLAGS) $(CXXFLAGS) calcCI.cpp

rsem-get-unique : $(SAMHEADERS) sam_utils.h utils.h getUnique.cpp $(SAMLIBS)
	$(CC) $(CPPFLAGS) $(CXXFLAGS) $(LDFLAGS) $(LFLAGS) $(SAMFLAGS) getUnique.cpp $(SAMLIBS) -lz -lpthread -o $@

rsem-sam-validator : $(SAMHEADERS) sam_utils.h utils.h my_assert.h samValidator.cpp $(SAMLIBS)
	$(CC) $(CPPFLAGS) $(CXXFLAGS) $(LDFLAGS) $(LFLAGS) $(SAMFLAGS) samValidator.cpp $(SAMLIBS) -lz -lpthread -o $@

rsem-scan-for-paired-end-reads : $(SAMHEADERS) sam_utils.h utils.h my_assert.h scanForPairedEndReads.cpp $(SAMLIBS)
	$(CC) $(CPPFLAGS) $(CXXFLAGS) $(LDFLAGS) $(LFLAGS) $(SAMFLAGS) scanForPairedEndReads.cpp $(SAMLIBS) -lz -lpthread -o $@

ebseq :
	cd EBSeq && ${MAKE} all

clean :
	rm -f *.o *~ $(PROGRAMS)
	cd $(SAMTOOLS) && ${MAKE} clean || /bin/true
	rm -f $(SAMLIBS)
	cd EBSeq && ${MAKE} clean || /bin/true
