<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:marc="http://www.loc.gov/MARC21/slim"
    xmlns:oai_pmh="http://www.openarchives.org/OAI/2.0/"
    xmlns:xpath="http://www.w3.org/2005/xpath-functions"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:foaf="http://xmlns.com/foaf/0.1/"
    xmlns:err="http://www.w3.org/2005/xqt-errors"
    xmlns:thread="java.lang.Thread"
    exclude-result-prefixes="xs marc oai_pmh owl rdf rdfs skos foaf err thread"
    version="3.0">
    
    <xsl:output encoding="UTF-8" indent="yes" method="xml"/>
    <xsl:strip-space elements="*"/>
    <xsl:key name="deprecatedFastURI" match="set" use="@deprecated-fastURI"/>
    <xsl:key name="changedHeadingFastURI" match="set" use="@changed-heading-fastURI"/>
    <xsl:key name="repoURI" match="set" use="@repoURI"/>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="data">
        <xsl:param name="repoDomain" select="repoDomain"/>
        <xsl:for-each select="namespace">
            <xsl:call-template name="oaiHarvest">
                <xsl:with-param name="namespace" select="." tunnel="yes"/>
                <xsl:with-param name="repoDomain" select="$repoDomain" tunnel="yes"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="oaiHarvest">
        <xsl:param name="namespace" tunnel="yes"/>
        <xsl:param name="repoDomain" tunnel="yes"/>
        <xsl:call-template name="repoURI-string-pid">
            <xsl:with-param name="mods" tunnel="yes">
                <mods:modsCollection>
                    <xsl:for-each select="document(concat($repoDomain,'/oai?verb=ListRecords&amp;metadataPrefix=mods&amp;set=',$namespace))">
                        <xsl:for-each select="oai_pmh:OAI-PMH">
                            <xsl:call-template name="modsExtract"/>
                        </xsl:for-each>
                    </xsl:for-each>
                </mods:modsCollection>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
        
    <xsl:template name="modsExtract">
        <xsl:for-each select="oai_pmh:ListRecords">
            <xsl:for-each select="oai_pmh:record">
                <!-- Retrieve local identifier which is the PID of the item in Fedora based on OAI identifier syntax 'oai-identifier = scheme ":" namespace-identifier ":" local-identifier' -->
                <xsl:variable name="pid" select="replace(substring-after(substring-after(oai_pmh:header/oai_pmh:identifier,':'),':'),'_',':')"/>
                <xsl:for-each select="oai_pmh:metadata/mods:mods">
                    <xsl:copy>
                        <xsl:copy-of select="*" copy-namespaces="no"/>
                        <xsl:element name="mods:identifier">
                            <xsl:attribute name="type">pid</xsl:attribute>
                            <xsl:value-of select="$pid"/>
                        </xsl:element>
                    </xsl:copy>
                </xsl:for-each>
            </xsl:for-each>
            <!-- Pause OAI call to avoid being blocked by server -->
            <xsl:call-template name="sleep"/>
            <!-- Use OAI resumption token to loop through pages of results -->
            <xsl:for-each select="oai_pmh:resumptionToken">
                <xsl:call-template name="resumptionToken">
                    <xsl:with-param name="resumptionToken" select="."/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="resumptionToken">
        <xsl:param name="resumptionToken"/>
        <xsl:param name="repoDomain" tunnel="yes"/>
        <xsl:for-each select="document(concat($repoDomain,'/oai?verb=ListRecords&amp;resumptionToken=',$resumptionToken))">
            <xsl:for-each select="oai_pmh:OAI-PMH">
                <xsl:call-template name="modsExtract"/>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="repoURI-string-pid">
        <xsl:param name="mods" tunnel="yes"/>
        <xsl:param name="namespace" tunnel="yes"/>
        <xsl:param name="repoDomain" tunnel="yes"/>
        
        <!-- Print harvested MODS records -->
        <xsl:result-document href="{concat($namespace,'/',$namespace)}_mods.xml">
            <xsl:copy-of select="$mods" copy-namespaces="no"/>
        </xsl:result-document>
        
        <!-- Create a lookup table of: FAST URI in repository, FAST heading string, PID -->
        <xsl:variable name="repoURI-string-pid">
            <xsl:for-each select="$mods//mods:mods">
                <xsl:for-each select="mods:subject[@authority='fast'][@valueURI]">
                    <xsl:element name="set">
                        <xsl:attribute name="repoURI">
                            <xsl:value-of select="@valueURI"/>
                        </xsl:attribute>
                        <xsl:attribute name="string">
                            <xsl:value-of select="child::node()" separator=" "/>
                        </xsl:attribute>
                        <xsl:attribute name="pid">
                            <xsl:value-of select="../mods:identifier[@type='pid']"/>
                        </xsl:attribute>
                    </xsl:element>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        
        <!-- Print "FAST URI in repository, FAST heading string, PID" lookup table -->
        <xsl:result-document href="{concat($namespace,'/',$namespace,'_repoURI-string-pid')}.xml">
            <xsl:copy-of select="$repoURI-string-pid" copy-namespaces="no"/>
        </xsl:result-document>
        
        <!-- Unique repo URI -->
        <xsl:variable name="repoURI">
            <xsl:for-each-group select="$repoURI-string-pid//set" group-by="@repoURI">
                <xsl:element name="repoURI">
                    <xsl:value-of select="xpath:current-grouping-key()"/>
                </xsl:element>
            </xsl:for-each-group>
        </xsl:variable>
        
        <!-- Create a lookup table of: Unique repo URI & string combination with PIDs -->
        <xsl:variable name="unique-repoURI-string-pids">
            <xsl:for-each-group select="$repoURI-string-pid//set" group-by="@repoURI">
                <xsl:element name="set">
                    <xsl:for-each-group select="xpath:current-group()" group-by="@string">
                        <xsl:copy-of select="@repoURI|@string"/>
                        <xsl:attribute name="pids">
                            <xsl:for-each select="../set[@string=xpath:current-grouping-key()]">
                                <xsl:choose>
                                    <xsl:when test="position()!=last()">
                                        <xsl:value-of select="@pid"/>
                                        <xsl:text>|</xsl:text>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="@pid"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                        </xsl:attribute>
                    </xsl:for-each-group>
                </xsl:element>
            </xsl:for-each-group>
        </xsl:variable>
        
        <!-- Print "Unique repo URI & string combination with PIDs" lookup table -->
        <xsl:result-document href="{concat($namespace,'/',$namespace,'_unique-repoURI-string-pids')}.xml">
            <xsl:copy-of select="$unique-repoURI-string-pids" copy-namespaces="no"/>
        </xsl:result-document>
        
        <!-- Create lookup table of: FAST URI in repository, FAST URI in OCLC, FAST heading string in OCLC, Deprecation status -->
        <xsl:variable name="repoURI-oclcURI-string-deprecation">
            <xsl:element name="sets">
                <xsl:for-each select="$repoURI//repoURI">
                    <xsl:variable name="repoURI" select="."/>
                    <xsl:call-template name="sleep"/>
                    <!-- Retrieve RDFXML of FAST URI -->
                    <xsl:for-each select="document(concat(.,'/rdf.xml'))">
                        <xsl:choose>
                            <!-- Deprecated FAST URI -->
                            <xsl:when test="//owl:deprecated[.='true']">
                                <!-- New FAST ID -->
                                <xsl:for-each select="//rdf:Description[@rdf:about=replace($repoURI,'\D','')]/rdfs:seeAlso">
                                    <xsl:element name="set">
                                        <xsl:attribute name="repoURI">
                                            <xsl:value-of select="$repoURI"/>
                                        </xsl:attribute>
                                        <xsl:attribute name="oclcURI">
                                            <xsl:value-of select="concat('http://id.worldcat.org/fast/',@rdf:resource)"/>
                                        </xsl:attribute>
                                        <xsl:attribute name="oclcLabel">
                                            <xsl:value-of select="document(concat('http://id.worldcat.org/fast/',@rdf:resource))//skos:prefLabel"/>
                                        </xsl:attribute>
                                        <xsl:attribute name="deprecation">
                                            <xsl:text>Y</xsl:text>
                                        </xsl:attribute>
                                    </xsl:element>
                                </xsl:for-each>
                            </xsl:when>
                            <!-- Non-deprecated FAST URI -->
                            <xsl:otherwise>
                                <xsl:element name="set">
                                    <xsl:attribute name="repoURI">
                                        <xsl:value-of select="$repoURI"/>
                                    </xsl:attribute>
                                    <xsl:attribute name="oclcURI">
                                        <xsl:value-of select="concat('http://id.worldcat.org/fast/',//foaf:primaryTopic/@rdf:resource)"/>
                                    </xsl:attribute>
                                    <xsl:attribute name="oclcLabel">
                                        <xsl:value-of select="//skos:prefLabel"/>
                                    </xsl:attribute>
                                    <xsl:attribute name="deprecation">
                                        <xsl:text>N</xsl:text>
                                    </xsl:attribute>
                                </xsl:element>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:element>
        </xsl:variable>
        
        <!-- Download redirected FAST MarcXML -->
        <xsl:for-each select="$repoURI-oclcURI-string-deprecation//set[@deprecation='Y']/@oclcURI">
            <xsl:result-document href="{concat($namespace,'/authority/',replace(.,'\D',''))}_marc21.xml">
                <xsl:copy-of select="document(concat(.,'/marc21.xml'))"/>
            </xsl:result-document>
        </xsl:for-each>
        
        <!-- Print "FAST URI in repository, FAST URI in OCLC, FAST heading string in OCLC, Deprecation status" lookup table -->
        <xsl:result-document href="{concat($namespace,'/',$namespace,'_repoURI-oclcURI-string-deprecation')}.xml">
            <xsl:copy-of select="$repoURI-oclcURI-string-deprecation" copy-namespaces="no"/>
        </xsl:result-document>
        
        <!-- Create lookup table of: PIDs grouped by Deprecated FAST URI -->
        <xsl:variable name="deprecated-fastURIs-pids-pair">
            <xsl:element name="sets">
                <xsl:for-each-group select="$repoURI-oclcURI-string-deprecation//set[@deprecation='Y']" group-by="@repoURI">
                    <set>
                        <xsl:attribute name="deprecated-fastURI">
                            <xsl:value-of select="current-grouping-key()"/>
                        </xsl:attribute>
                        <xsl:attribute name="pids">
                            <xsl:variable name="pids">
                                <xsl:for-each select="key('repoURI',xpath:current-grouping-key(),$repoURI-string-pid)">
                                    <xsl:element name="pid">
                                        <xsl:value-of select="@pid"/>
                                    </xsl:element>
                                </xsl:for-each>
                            </xsl:variable>
                            <xsl:value-of select="$pids//pid" separator="|"/>
                        </xsl:attribute>
                    </set>
                </xsl:for-each-group>
            </xsl:element>
        </xsl:variable>
        
        <!-- Print "PIDs grouped by Deprecated FAST URI" lookup table -->
        <xsl:result-document href="{concat($namespace,'/',$namespace,'_deprecated-fastURIs-pids-table')}.xml">
            <xsl:copy-of select="$deprecated-fastURIs-pids-pair" copy-namespaces="no"/>
        </xsl:result-document>
        
        <!-- Create lookup table of: Repository FAST URIs with changed heading, FAST heading string in repository, FAST heading string in OCLC, PIDs -->
        <xsl:variable name="changed-heading-fastURIs-pids-pair">
            <xsl:element name="sets">
                <xsl:for-each select="$unique-repoURI-string-pids//set">
                    <xsl:variable name="fast-uri" select="@repoURI"/>
                    <xsl:choose>
                        <xsl:when test="key('deprecatedFastURI',$fast-uri,$deprecated-fastURIs-pids-pair)"/>
                        <xsl:otherwise>
                            <xsl:variable name="oclc-subject-string">
                                <xsl:for-each select="document(concat($fast-uri,'/rdf.xml'))">
                                    <xsl:value-of select="//skos:prefLabel"/>
                                </xsl:for-each>
                            </xsl:variable>
                            <xsl:if test="lower-case(replace(@string,'[\p{P} ]',''))!=lower-case(replace($oclc-subject-string,'[\p{P} ]',''))">
                                <set>
                                    <xsl:attribute name="changed-heading-fastURI">
                                        <xsl:value-of select="$fast-uri"/>
                                    </xsl:attribute>
                                    <xsl:attribute name="repo-subject-string">
                                        <xsl:value-of select="@string"/>
                                    </xsl:attribute>
                                    <xsl:attribute name="oclc-subject-string">
                                        <xsl:value-of select="$oclc-subject-string"/>
                                    </xsl:attribute>
                                    <xsl:attribute name="pids">
                                        <xsl:value-of select="@pids"/>
                                    </xsl:attribute>
                                </set>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:element>
        </xsl:variable>
        
        <!-- Download updated FAST authority MarcXML -->
        <xsl:for-each select="$changed-heading-fastURIs-pids-pair//set/@changed-heading-fastURI">
            <xsl:result-document href="{concat($namespace,'/authority/',replace(.,'\D',''))}_marc21.xml">
                <xsl:copy-of select="document(concat(.,'/marc21.xml'))"/>
            </xsl:result-document>
        </xsl:for-each>
        
        <!-- Print "Repository FAST URIs with changed heading, FAST heading string in repository, FAST heading string in OCLC, PIDs" lookup table -->
        <xsl:result-document href="{concat($namespace,'/',$namespace,'_changed-heading-fastURIspids-table')}.xml">
            <xsl:copy-of select="$changed-heading-fastURIs-pids-pair" copy-namespaces="no"/>
        </xsl:result-document>
        
        <!-- Extract PIDs with deprecated or changed headings -->
        <xsl:variable name="pids">
            <xsl:for-each select="$deprecated-fastURIs-pids-pair//@pids|$changed-heading-fastURIs-pids-pair//@pids">
                <xsl:analyze-string select="." regex=".+\|.+">
                    <xsl:matching-substring>
                        <xsl:for-each select="tokenize(.,'\|')">
                            <pid>
                                <xsl:value-of select="."/>
                            </pid>
                        </xsl:for-each>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <pid>
                            <xsl:value-of select="."/>
                        </pid>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:for-each>
        </xsl:variable>
        
        <!-- Correct MODS record -->
        <xsl:for-each select="$pids">
            <xsl:for-each-group select="*" group-by=".">
                <xsl:call-template name="sleep"/>
                <!-- Retrieve MODS of PIDs with changed or deprecated FAST heading -->
                <xsl:for-each select="document(concat($repoDomain,'/',replace(xpath:current-grouping-key(),':','/'),'/MODS/view/'))">
                    <xsl:variable name="mods">
                        <xsl:apply-templates mode="mods-copy">
                            <xsl:with-param name="deprecated-fastURIs-pids-pair" select="$deprecated-fastURIs-pids-pair" tunnel="yes"/>
                            <xsl:with-param name="changed-heading-fastURIs-pids-pair" select="$changed-heading-fastURIs-pids-pair" tunnel="yes"/>
                            <xsl:with-param name="repoURI-oclcURI-string-deprecation" select="$repoURI-oclcURI-string-deprecation" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    <xsl:try>
                        <xsl:result-document href="{concat(replace(xpath:current-grouping-key(),'[\d\p{P}]',''),'/mods/',$mods//mods:identifier[@type='filename'])}_mods.xml">
                            <xsl:copy-of select="$mods" copy-namespaces="no"/>
                        </xsl:result-document>
                        <!-- Handle fatal error XTDE1490 when trying to write to the same filename more than once -->
                        <xsl:catch errors="err:XTDE1490">
                            <xsl:message select="concat('Attempt to write more than once to ',$mods//mods:identifier[@type='filename'])"/>
                        </xsl:catch>
                    </xsl:try>
                </xsl:for-each>
            </xsl:for-each-group>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Identity transform template -->
    <xsl:template match="node()|@*" mode="mods-copy">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="mods-copy"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Template to change FAST heading -->
    <xsl:template match="mods:subject[contains(@valueURI,'fast')]" mode="mods-copy">
        <xsl:param name="deprecated-fastURIs-pids-pair" tunnel="yes"/>
        <xsl:param name="changed-heading-fastURIs-pids-pair" tunnel="yes"/>
        <xsl:param name="repoURI-oclcURI-string-deprecation" tunnel="yes"/>
        <xsl:param name="namespace" tunnel="yes"/>
        <xsl:choose>
            <!-- FAST URIs with deprecated heading -->
            <xsl:when test="key('deprecatedFastURI',@valueURI,$deprecated-fastURIs-pids-pair)">
                <xsl:for-each select="key('repoURI',@valueURI,$repoURI-oclcURI-string-deprecation)">
                    <xsl:variable name="oclcURI" select="@oclcURI"/>
                    <!-- Adding ?version=1 to avoid "XTRE1500: Cannot read a document that was written during the same transformation" error -->
                    <xsl:for-each select="document(concat($namespace,'/authority/',replace(@oclcURI,'\D',''),'_marc21.xml?version=1'))">
                        <xsl:call-template name="fastHeading-marc2mods"/>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:when>
            <!-- FAST URIs with changed heading -->
            <xsl:when test="key('changedHeadingFastURI',@valueURI,$changed-heading-fastURIs-pids-pair)">
                <!-- Adding ?version=1 to avoid "XTRE1500: Cannot read a document that was written during the same transformation" error -->
                <xsl:for-each select="document(concat($namespace,'/authority/',replace(@valueURI,'\D',''),'_marc21.xml?version=1'))">
                    <xsl:call-template name="fastHeading-marc2mods"/>
                </xsl:for-each>
            </xsl:when>
            <!-- FAST URIs with no change in heading -->
            <xsl:otherwise>
                <xsl:copy-of select="self::mods:subject" copy-namespaces="no"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Template to transform FAST heading in MARC 6XX encoding into <mods:subject> encoding -->
    <xsl:template name="fastHeading-marc2mods">
        <xsl:param name="valueURI">
            <xsl:for-each select="//marc:controlfield[@tag=001]">
                <xsl:text>http://id.worldcat.org/fast/</xsl:text>
                <xsl:call-template name="chopLeadingZero">
                    <xsl:with-param name="fastID" select="replace(.,'\D','')"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:param>
        <!-- Output FAST personal/family name subject -->
        <xsl:for-each select="//marc:datafield[@tag=100]">
            <mods:subject authority="fast" authorityURI="http://id.worldcat.org/fast" valueURI="{$valueURI}">
                <xsl:variable name="type">
                    <xsl:choose>
                        <xsl:when test="@ind1='3'">
                            <xsl:text>family</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>personal</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <mods:name type="{$type}">
                    <xsl:for-each select="marc:subfield[not(@code='0') and not(@code='2')]">
                        <xsl:choose>
                            <xsl:when test="@code='d'">
                                <mods:namePart type="date">
                                    <xsl:value-of select="normalize-unicode(normalize-unicode(.,'NFKD'),'NFKC')"/>
                                </mods:namePart>
                            </xsl:when>
                            <xsl:when test="@code='b' or @code='c'">
                                <mods:namePart type="termsOfAddress">
                                    <xsl:value-of select="normalize-unicode(normalize-unicode(.,'NFKD'),'NFKC')"/>
                                </mods:namePart>
                            </xsl:when>
                            <xsl:otherwise>
                                <mods:namePart>
                                    <xsl:value-of select="normalize-unicode(normalize-unicode(.,'NFKD'),'NFKC')"/>
                                </mods:namePart>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </mods:name>
            </mods:subject>
        </xsl:for-each>
        <!-- Output FAST corporate name subject -->
        <xsl:for-each select="//marc:datafield[@tag=110]">
            <mods:subject authority="fast" authorityURI="http://id.worldcat.org/fast" valueURI="{$valueURI}">
                <mods:name type="corporate">
                    <xsl:for-each select="marc:subfield[not(@code='0') and not(@code='2')]">
                        <mods:namePart>
                            <xsl:value-of select="normalize-unicode(normalize-unicode(.,'NFKD'),'NFKC')"/>
                        </mods:namePart>
                    </xsl:for-each>
                </mods:name>
            </mods:subject>
        </xsl:for-each>
        <!-- Output FAST conference name subject -->
        <xsl:for-each select="//marc:datafield[@tag=111]">
            <mods:subject authority="fast" authorityURI="http://id.worldcat.org/fast" valueURI="{$valueURI}">
                <mods:name type="conference">
                    <xsl:for-each select="marc:subfield[not(@code='0') and not(@code='2')]">
                        <mods:namePart>
                            <xsl:value-of select="normalize-unicode(normalize-unicode(.,'NFKD'),'NFKC')"/>
                        </mods:namePart>
                    </xsl:for-each>
                </mods:name>
            </mods:subject>
        </xsl:for-each>
        <!-- Output FAST title subject -->
        <xsl:for-each select="//marc:datafield[@tag=130]">
            <mods:subject authority="fast" authorityURI="http://id.worldcat.org/fast" valueURI="{$valueURI}">
                <mods:titleInfo>
                    <xsl:for-each select="marc:subfield[not(@code='0') and not(@code='2')]">
                        <xsl:choose>
                            <xsl:when test="@code='n'">
                                <mods:partNumber>
                                    <xsl:value-of select="normalize-unicode(normalize-unicode(.,'NFKD'),'NFKC')"/>
                                </mods:partNumber>
                            </xsl:when>
                            <xsl:when test="@code='p'">
                                <mods:partName>
                                    <xsl:value-of select="normalize-unicode(normalize-unicode(.,'NFKD'),'NFKC')"/>
                                </mods:partName>
                            </xsl:when>
                            <xsl:otherwise>
                                <mods:title>
                                    <xsl:value-of select="normalize-unicode(normalize-unicode(.,'NFKD'),'NFKC')"/>
                                </mods:title>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </mods:titleInfo>
            </mods:subject>
        </xsl:for-each>
        <!-- Output FAST event subject -->
        <xsl:for-each select="//marc:datafield[@tag=147]">
            <mods:subject authority="fast" authorityURI="http://id.worldcat.org/fast" valueURI="{$valueURI}">
                <mods:topic>
                    <xsl:for-each select="marc:subfield[not(@code='0') and not(@code='2')]">
                        <xsl:value-of select="normalize-unicode(normalize-unicode(.,'NFKD'),'NFKC')"/>
                        <xsl:if test="position()!=last()">
                            <xsl:text> </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </mods:topic>
            </mods:subject>
        </xsl:for-each>
        <!-- Output FAST temporal subject -->
        <xsl:for-each select="//marc:datafield[@tag=148]">
            <mods:subject authority="fast" authorityURI="http://id.worldcat.org/fast" valueURI="{$valueURI}">
                <xsl:for-each select="marc:subfield[@code='a']|marc:subfield[@code='y']">
                    <mods:temporal>
                        <xsl:value-of select="normalize-unicode(normalize-unicode(.,'NFKD'),'NFKC')"/>
                    </mods:temporal>
                </xsl:for-each>
            </mods:subject>
        </xsl:for-each>
        <!-- Output FAST topical subject -->
        <xsl:for-each select="//marc:datafield[@tag=150]">
            <mods:subject authority="fast" authorityURI="http://id.worldcat.org/fast" valueURI="{$valueURI}">
                <xsl:for-each select="marc:subfield[@code='a']|marc:subfield[@code='x']">
                    <mods:topic>
                        <xsl:value-of select="normalize-unicode(normalize-unicode(.,'NFKD'),'NFKC')"/>
                    </mods:topic>
                </xsl:for-each>
            </mods:subject>
        </xsl:for-each>
        <!-- Output FAST geographic subject -->
        <xsl:for-each select="//marc:datafield[@tag=151]">
            <mods:subject authority="fast" authorityURI="http://id.worldcat.org/fast" valueURI="{$valueURI}">
                <xsl:for-each select="marc:subfield[@code='a']|marc:subfield[@code='z']">
                    <mods:geographic>
                        <xsl:value-of select="normalize-unicode(normalize-unicode(.,'NFKD'),'NFKC')"/>
                    </mods:geographic>
                </xsl:for-each>
            </mods:subject>
        </xsl:for-each>
        <!-- Output FAST genre -->
        <xsl:for-each select="//marc:datafield[@tag=155]">
            <mods:genre authority="fast" authorityURI="http://id.worldcat.org/fast" valueURI="{$valueURI}">
                <xsl:value-of select="normalize-unicode(normalize-unicode(marc:subfield[@code='a'],'NFKD'),'NFKC'),normalize-unicode(normalize-unicode(marc:subfield[@code='v'],'NFKD'),'NFKC')" separator="--"/>
            </mods:genre>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Remove leading zero(es) from FAST identifier -->
    <xsl:template name="chopLeadingZero">
        <xsl:param name="fastID"/>
        <xsl:choose>
            <xsl:when test="starts-with($fastID,'0')">
                <xsl:call-template name="chopLeadingZero">
                    <xsl:with-param name="fastID" select="substring($fastID,2)"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$fastID"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Template to pause XSLT process -->
    <xsl:template name="sleep">
        <xsl:value-of select="thread:sleep(10)"/>
    </xsl:template>
</xsl:stylesheet>