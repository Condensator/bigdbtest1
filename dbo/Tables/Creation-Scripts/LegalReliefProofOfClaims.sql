SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LegalReliefProofOfClaims](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Date] [date] NULL,
	[FilingDate] [date] NULL,
	[ClaimNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalAmount_Amount] [decimal](16, 2) NULL,
	[TotalAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[Active] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StateId] [bigint] NULL,
	[OriginalPOCId] [bigint] NULL,
	[LegalReliefId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LegalReliefProofOfClaims]  WITH CHECK ADD  CONSTRAINT [ELegalRelief_LegalReliefProofOfClaims] FOREIGN KEY([LegalReliefId])
REFERENCES [dbo].[LegalReliefs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LegalReliefProofOfClaims] CHECK CONSTRAINT [ELegalRelief_LegalReliefProofOfClaims]
GO
ALTER TABLE [dbo].[LegalReliefProofOfClaims]  WITH CHECK ADD  CONSTRAINT [ELegalReliefProofOfClaim_OriginalPOC] FOREIGN KEY([OriginalPOCId])
REFERENCES [dbo].[LegalReliefProofOfClaims] ([Id])
GO
ALTER TABLE [dbo].[LegalReliefProofOfClaims] CHECK CONSTRAINT [ELegalReliefProofOfClaim_OriginalPOC]
GO
ALTER TABLE [dbo].[LegalReliefProofOfClaims]  WITH CHECK ADD  CONSTRAINT [ELegalReliefProofOfClaim_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[LegalReliefProofOfClaims] CHECK CONSTRAINT [ELegalReliefProofOfClaim_State]
GO
