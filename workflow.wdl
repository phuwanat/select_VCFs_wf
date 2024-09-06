version 1.0

workflow filter_VCFs {

    meta {
	author: "Phuwanat Sakornsakolpat"
        email: "phuwanat.sak@mahidol.edu"
        description: "Filter VCF"
    }

     input {
        Array[File] vcf_files
    }

    scatter(this_file in vcf_files) {
		call run_filtering { 
			input: vcf = this_file
		}
	}

    output {
        Array[File] filtered_vcf = run_filtering.out_file
        Array[File] filtered_tbi = run_filtering.out_file_tbi
    }

}

task run_filtering {
    input {
        File vcf
        Int memSizeGB = 8
        Int threadCount = 2
        Int diskSizeGB = 8*round(size(vcf, "GB")) + 20
	String out_name = basename(vcf, ".vcf.gz")
    }
    
    command <<<
	tabix -p vcf ~{vcf}
	bcftools view -i 'F_MISSING < 0.05 && FILTER="PASS"' -o ~{out_name}.filtered0.vcf.gz ~{vcf}
	tabix -p vcf ~{out_name}.filtered0.vcf.gz
	bcftools sort -m 2G -Oz -o ~{out_name}.filtered.vcf.gz ~{out_name}.filtered0.vcf.gz
	tabix -p vcf ~{out_name}.filtered.vcf.gz
    >>>

    output {
        File out_file = select_first(glob("*.filtered.vcf.gz"))
        File out_file_tbi = select_first(glob("*.filtered.vcf.gz.tbi"))
    }

    runtime {
        memory: memSizeGB + " GB"
        cpu: threadCount
        disks: "local-disk " + diskSizeGB + " SSD"
        docker: "quay.io/biocontainers/bcftools@sha256:f3a74a67de12dc22094e299fbb3bcd172eb81cc6d3e25f4b13762e8f9a9e80aa"   # digest: quay.io/biocontainers/bcftools:1.16--hfe4b78e_1
        preemptible: 2
    }

}
